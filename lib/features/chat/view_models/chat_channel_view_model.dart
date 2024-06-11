import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  StreamSubscription<QuerySnapshot>? _channelsSubscription;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setChatChannels(List<Map<String, dynamic>> chatChannels) {
    _chatChannels = chatChannels;
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
    String? channelId = await _chatChannelRepo.createChannel(
      channelTitle: channelTitle,
      sendUserId: sendUserId,
      receiveUserId: receiveUserId,
    );

    if (channelId != null) {
      subscribeToChatChannels(sendUserId);
      _setErrorMessage('');
    } else {
      _setErrorMessage('새 채널 생성 실패');
    }
    _setLoading(false);
  }

  void subscribeToChatChannels(String userId) {
    _setLoading(true);

    _channelsSubscription?.cancel();
    _channelsSubscription = FirebaseFirestore.instance
        .collection('chatChannels')
        .where('participantsIds', arrayContains: userId)
        .snapshots()
        .listen(
      (querySnapshot) {
        List<Map<String, dynamic>> chatChannels =
            querySnapshot.docs.map((doc) => doc.data()).toList();
        _setChatChannels(chatChannels);
        _setLoading(false);
      },
      onError: (error) {
        _setErrorMessage('채널 패치 실패: $error');
        _setLoading(false);
      },
    );
  }

  void unsubscribeFromChatChannels() {
    _channelsSubscription?.cancel();
    _channelsSubscription = null;
  }

  // // subscribe 방식으로 변경하면서 지금은 사용안하지만 추후 사용 로직 변경시 재사용 가능
  // Future<void> fetchChatChannels(String userId) async {
  //   _setLoading(true);
  //   _chatChannels = await _chatChannelRepo.getChatChannels(userId);
  //   _setLoading(false);
  //   notifyListeners();
  // }

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
      _setErrorMessage('채널 차단 실패');
    }
    _setLoading(false);
  }

  Future<void> deleteChannel(String channelId) async {
    _setLoading(true);
    bool isSuccess = await _chatChannelRepo.deleteChannel(channelId);

    if (isSuccess) {
      _chatChannels.removeWhere((channel) => channel['channelId'] == channelId);
      _setErrorMessage('');
      notifyListeners();
    } else {
      _setErrorMessage('채널 삭제 실패');
    }
    _setLoading(false);
  }

  @override
  void dispose() {
    unsubscribeFromChatChannels();
    super.dispose();
  }
}
