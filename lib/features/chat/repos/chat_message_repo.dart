import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> sendMessage({
    required String channelId,
    required String sendUserId,
    required String receiveUserId,
    required String message,
    required String messageType,
    List<String>? metaPathList,
  }) async {
    try {
      String messageId = _db
          .collection('chatChannels')
          .doc(channelId)
          .collection('messages')
          .doc()
          .id;

      await _db
          .collection("chatChannels")
          .doc(channelId)
          .collection('messages')
          .doc(messageId)
          .set({
        'messageId': messageId,
        'userId': sendUserId,
        'message': message,
        'messageType': messageType,
        'metaPathList': metaPathList,
        'readStatus': {
          sendUserId: true,
          receiveUserId: false,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('[ChatMessageRepo][sendMessage] error: $e');
      return false;
    }
  }

  StreamSubscription<QuerySnapshot> subscribeToMessages({
    required String channelId,
    required Function(List<Map<String, dynamic>>) onData,
    required Function(String) onError,
  }) {
    return FirebaseFirestore.instance
        .collection('chatChannels')
        .doc(channelId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .listen(
      (querySnapshot) {
        List<Map<String, dynamic>> messages =
            querySnapshot.docs.map((doc) => doc.data()).toList();
        onData(messages);
      },
      onError: (error) {
        onError('메시지 패치 실패: $error');
      },
    );
  }

  Future<List<Map<String, dynamic>>> getMessages(String channelId) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('chatChannels')
          .doc(channelId)
          .collection('messages')
          .orderBy('createdAt')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('[ChatMessageRepo][getMessages] error: $e');
      return [];
    }
  }

  Future<bool> updateReadStatus({
    required String channelId,
    required String userId,
  }) async {
    try {
      WriteBatch batch = _db.batch();

      QuerySnapshot querySnapshot = await _db
          .collection('chatChannels')
          .doc(channelId)
          .collection('messages')
          .get();

      for (DocumentSnapshot doc in querySnapshot.docs) {
        DocumentReference messageRef = doc.reference;
        batch.update(messageRef, {
          'readStatus.$userId': true,
        });
      }

      await batch.commit();

      return true;
    } catch (e) {
      print('[ChatMessageRepo][updateReadStatus] error: $e');
      return false;
    }
  }
}
