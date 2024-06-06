import 'package:cloud_firestore/cloud_firestore.dart';

class ChatChannelRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 현재: 1:1 채팅만 고려, 추후 여러 유저를 동시 초대시 List<String> receiveUserIds로 변경 가능
  Future<bool> createChannel({
    required String sendUserId,
    required String receiveUserId,
    String? channelTitle,
    String? imagePath,
    String? channelType,
  }) async {
    try {
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

      return true;
    } catch (e) {
      print('[ChatChannelRepo][createChannel] error: $e');
      return false;
    }
  }

  // block: true - block, false - unblock
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
}
