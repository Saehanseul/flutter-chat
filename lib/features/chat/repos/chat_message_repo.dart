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
    required String messageId,
    required String userId,
  }) async {
    try {
      DocumentReference messageRef = _db
          .collection('chatChannels')
          .doc(channelId)
          .collection('messages')
          .doc(messageId);

      await _db.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(messageRef);

        if (!snapshot.exists) {
          throw Exception("Message does not exist!");
        }

        Map<String, dynamic> readStatus = snapshot.get('readStatus');
        readStatus[userId] = true;

        transaction.update(messageRef, {'readStatus': readStatus});
      });

      return true;
    } catch (e) {
      print('[ChatMessageRepo][updateReadStatus] error: $e');
      return false;
    }
  }
}
