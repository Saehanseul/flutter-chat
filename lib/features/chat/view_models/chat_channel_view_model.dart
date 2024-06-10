import 'package:flutter/material.dart';
import 'package:flutter_chat/features/chat/repos/chat_channel_repo.dart';

class ChatChannelViewModel extends ChangeNotifier {
  final ChatChannelRepo _chatChannelRepo = ChatChannelRepo();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<Map<String, dynamic>> _chatChannels = [];
  List<Map<String, dynamic>> get chatChannels => _chatChannels;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> createChannel({
    required String sendUserId,
    required String receiveUserId,
    String? channelTitle,
    String? imagePath,
    String? channelType,
  }) async {
    _setLoading(true);
    bool isSuccess = await _chatChannelRepo.createChannel(
      channelTitle: channelTitle,
      sendUserId: sendUserId,
      receiveUserId: receiveUserId,
    );

    if (isSuccess) {
      await fetchChatChannels(sendUserId);
      _setErrorMessage('');
    } else {
      _setErrorMessage('Failed to create channel');
    }
    _setLoading(false);
  }

  Future<void> fetchChatChannels(String userId) async {
    _setLoading(true);
    _chatChannels = await _chatChannelRepo.getChatChannels(userId);
    _setLoading(false);
    notifyListeners();
  }

  Future<void> blockChannel({
    required String channelId,
    required String userId,
    required bool block,
  }) async {
    _setLoading(true);
    bool isSuccess = await _chatChannelRepo.blockChannel(
      channelId: channelId,
      userId: userId,
      block: block,
    );

    if (isSuccess) {
      _setErrorMessage('');
    } else {
      _setErrorMessage('Failed to block channel');
    }
    _setLoading(false);
  }

  Future<void> deleteChannel({
    required String channelId,
  }) async {
    _setLoading(true);
    bool isSuccess = await _chatChannelRepo.deleteChannel(
      channelId: channelId,
    );

    if (isSuccess) {
      _chatChannels.removeWhere((channel) => channel['channelId'] == channelId);
      _setErrorMessage('');
      notifyListeners();
    } else {
      _setErrorMessage('Failed to delete channel');
    }
    _setLoading(false);
  }
}
