import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatChannelRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 현재: 1:1 채팅만 고려, 추후 여러 유저를 동시 초대시 List<String> receiveUserIds로 변경 가능
  Future<String?> createChannel({
    required String sendUserId,
    required String receiveUserId,
    String? channelTitle,
    String? imagePath,
    String? channelType,
  }) async {
    try {
      /** [array-contains] 제약으로 인해 한번의 쿼리로 두개의 arrayContains 조건 불가 */
      // sendUserId가 포함된 채널들 가져오기
      QuerySnapshot sendUserChannels = await _db
          .collection("chatChannels")
          .where('participantsIds', arrayContains: sendUserId)
          .get();

      // receiveUserId가 포함된 채널들 가져오기
      QuerySnapshot receiveUserChannels = await _db
          .collection("chatChannels")
          .where('participantsIds', arrayContains: receiveUserId)
          .get();

      // 두 결과를 클라이언트 측에서 비교하여 기존 채널 찾기
      for (var sendDoc in sendUserChannels.docs) {
        for (var receiveDoc in receiveUserChannels.docs) {
          if (sendDoc.id == receiveDoc.id) {
            return sendDoc.id;
          }
        }
      }
      /** [array-contains] */

      /** [기존 채널이 없으면 새로운 채널 생성] */
      String channelId = _db.collection('chatChannels').doc().id;

      await _db.collection("chatChannels").doc(channelId).set({
        'channelId': channelId,
        // 'title': channelTitle, // 추후 채널명 필요한 경우 사용, 현재는 상대방 이름
        // 'imagePath': imagePath, // 현재는 상대방 프로필, 추후 채널 이미지 변경시 사용
        // 'channelType': channelType, // 추후 public, private, group 등으로 변경 가능

        'participantsIds': [
          sendUserId,
          receiveUserId,
        ],
        'createUserId': sendUserId,
        'unreadCounts': {
          sendUserId: 0,
          receiveUserId: 1,
        },
        'blockedUsers': {
          sendUserId: {
            'isBlocked': false,
            'blockedAt': null,
          },
          receiveUserId: {
            'isBlocked': false,
            'blockedAt': null,
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return channelId;
      /** [기존 채널이 없으면 새로운 채널 생성] */
    } catch (e) {
      print('[ChatChannelRepo][createChannel] error: $e');
      return null;
    }
  }

  /// 해당 유저가 참여한 모든 채널 리스트 구독
  StreamSubscription<QuerySnapshot> subscribeToChatChannels({
    required String userId,
    required Function(List<Map<String, dynamic>>) onData,
    required Function(String) onError,
  }) {
    return FirebaseFirestore.instance
        .collection('chatChannels')
        .where('participantsIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (querySnapshot) {
        List<Map<String, dynamic>> chatChannels =
            querySnapshot.docs.map((doc) => doc.data()).toList();
        onData(chatChannels);
      },
      onError: (error) {
        onError('채널 패치 실패: $error');
      },
    );
  }

  /// 해당 유저가 참여한 모든 채널 리스트 가져오기
  /// 현재는 subscribe로 대체하면서 사용하지 않음
  Future<List<Map<String, dynamic>>> getChatChannels(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('chatChannels')
          .where('participantsIds', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('[ChatChannelRepo][getChatChannels] error: $e');
      return [];
    }
  }

  /// 유저가 채널에 메시지 발송시 channel의 lastMessage, lastMessageSenderId, unreadCounts 업데이트
  Future<bool> updateChannelWithLastMessage({
    required String channelId,
    required String lastMessage,
    required String lastMessageSenderId,
  }) async {
    try {
      DocumentReference channelRef =
          _db.collection('chatChannels').doc(channelId);
      DocumentSnapshot channelSnapshot = await channelRef.get();

      if (!channelSnapshot.exists) {
        throw Exception('Channel not found');
      }

      Map<String, dynamic> unreadCounts =
          Map<String, dynamic>.from(channelSnapshot['unreadCounts']);

      unreadCounts.forEach((userId, count) {
        if (userId != lastMessageSenderId) {
          unreadCounts[userId] = count + 1;
        }
      });

      await channelRef.update({
        'lastMessage': lastMessage,
        'lastMessageSenderId': lastMessageSenderId,
        'unreadCounts': unreadCounts,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('[ChatChannelRepo][updateChannelWithLastMessage] error: $e');
      return false;
    }
  }

  /// 특정 유저의 특정 채널의 unreadCount를 업데이트
  /// 지금은 해당 채널 진입시 기존 unreadCount를 0으로 초기화 용도로 사용
  Future<bool> updateUserUnreadCount({
    required String channelId,
    required String userId,
    int count = 0,
  }) async {
    try {
      DocumentReference channelRef =
          _db.collection('chatChannels').doc(channelId);

      await channelRef.update({
        'unreadCounts.$userId': count,
        // 'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('[ChatChannelRepo][updateUserUnreadCount] error: $e');
      return false;
    }
  }

  /// 채널 차단 / 해제
  /// 차단 block: true, 해제 block: false
  /// return 성공: true, 실패: false
  Future<bool> blockChannel({
    required String channelId,
    required String userId,
    required bool block,
  }) async {
    try {
      await _db.collection("chatChannels").doc(channelId).update({
        'blockedUsers.$userId': {
          'isBlocked': block,
          'blockedAt': block ? FieldValue.serverTimestamp() : null,
        },
      });
      return true;
    } catch (e) {
      print('[ChatChannelRepo][blockChannel] error: $e');
      return false;
    }
  }

  /// 채널 차단 여부 확인
  /// return 차단 된 경우: true, 차단되지 않은 경우: false, 에러 발생: null
  Future<bool?> isChannelBlocked(String channelId) async {
    try {
      DocumentSnapshot channelSnapshot =
          await _db.collection('chatChannels').doc(channelId).get();

      if (!channelSnapshot.exists) {
        throw Exception('Channel not found');
      }

      Map<String, dynamic> blockedUsers =
          channelSnapshot['blockedUsers'] as Map<String, dynamic>;

      return blockedUsers.values.any((user) => user['isBlocked'] == true);
    } catch (e) {
      print('[ChatChannelRepo][isChannelBlocked] error: $e');
      return null;
    }
  }

  Future<bool> deleteChannel(String channelId) async {
    try {
      // 채널 내의 모든 메시지 삭제 (삭제하지 않는 경우 불필요한 메모리 낭비 발생)
      QuerySnapshot messagesSnapshot = await _db
          .collection('chatChannels')
          .doc(channelId)
          .collection('messages')
          .get();
      for (DocumentSnapshot doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // 채널 삭제
      await _db.collection("chatChannels").doc(channelId).delete();
      return true;
    } catch (e) {
      print('[ChatChannelRepo][deleteChannel] error: $e');
      return false;
    }
  }
}
