import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/features/chat/repos/chat_channel_repo.dart';
import 'package:flutter_chat/features/chat/repos/chat_message_repo.dart';

class ChatMessageViewModel extends ChangeNotifier {
  final ChatMessageRepo _chatMessageRepo = ChatMessageRepo();
  final ChatChannelRepo _chatChannelRepo = ChatChannelRepo();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setMessages(List<Map<String, dynamic>> messages) {
    _messages = messages;
    notifyListeners();
  }

  Future<void> sendMessage({
    required String channelId,
    required String sendUserId,
    required String receiveUserId,
    required String message,
    String messageType = 'text',
    List<String>? metaPathList,
  }) async {
    _setLoading(true);

    bool isSuccess = await _chatMessageRepo.sendMessage(
      channelId: channelId,
      sendUserId: sendUserId,
      receiveUserId: receiveUserId,
      message: message,
      messageType: messageType,
      metaPathList: metaPathList,
    );
    if (isSuccess) {
      _setErrorMessage('');
      await _chatChannelRepo.updateChannelWithLastMessage(
        channelId: channelId,
        lastMessage: message,
        lastMessageSenderId: sendUserId,
      );
    } else {
      _setErrorMessage('Failed to send message');
    }
    _setLoading(false);
  }

  // Future<void> fetchMessages(String channelId) async {
  //   _setLoading(true);

  //   try {
  //     List<Map<String, dynamic>> messages =
  //         await _chatMessageRepo.getMessages(channelId);
  //     _setMessages(messages);
  //     _setErrorMessage('');
  //   } catch (e) {
  //     _setErrorMessage('Failed to fetch messages');
  //   }

  //   _setLoading(false);
  // }

  void subscribeToMessages(String channelId) {
    _messagesSubscription?.cancel();
    _messagesSubscription = FirebaseFirestore.instance
        .collection('chatChannels')
        .doc(channelId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .listen((querySnapshot) {
      List<Map<String, dynamic>> messages =
          querySnapshot.docs.map((doc) => doc.data()).toList();
      _setMessages(messages);
    });
  }

  void unsubscribeFromMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
  }

  Future<void> updateReadStatus(String channelId, String userId) async {
    _setLoading(true);
    bool isSuccess = await _chatMessageRepo.updateReadStatus(
      channelId: channelId,
      userId: userId,
    );
    if (isSuccess) {
      _setErrorMessage('');
      await _chatChannelRepo.updateUserUnreadCount(
          channelId: channelId, userId: userId, count: 0);
    } else {
      _setErrorMessage('Failed to update read status');
    }
    _setLoading(false);
  }

  @override
  void dispose() {
    unsubscribeFromMessages();
    super.dispose();
  }
}
