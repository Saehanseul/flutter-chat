import 'package:cloud_firestore/cloud_firestore.dart';

class ChatChannelRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 현재: 1:1 채팅만 고려, 추후 여러 유저를 동시 초대시 List<String> receiveUserIds로 변경 가능
  Future<void> createChannel(
    String channelName,
    String sendUserId,
    String receiveUserId,
  ) async {
    try {
      String channelId = _db.collection('chatChannels').doc().id;

      await _db.collection("chatChannels").add({
        'channelId': channelId,
        'name': channelName,
        'userIds': [sendUserId, receiveUserId],
        'userId': sendUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('[ChatChannelRepo][createChannel] error: $e');
    }
  }

  Future<void> blockChannel() async {}
}
