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

  /// 채널 생성
  /// 현재는 sendUserId, receiveUserId 2개만 사용하여 생성 가능
  /// 비즈니스 로직에 따라 title, imagePath, channelType 등 추가 가능
  Future<String?> createChannel({
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
      await subscribeToChatChannels(sendUserId);
      _setErrorMessage('');
    } else {
      _setErrorMessage('새 채널 생성 실패');
    }
    _setLoading(false);
    return channelId;
  }

  /// 해당 유저가 참여한 모든 채널 구독
  Future<void> subscribeToChatChannels(String userId) async {
    _setLoading(true);

    _channelsSubscription?.cancel();
    Completer<void> completer = Completer<void>();

    _channelsSubscription = _chatChannelRepo.subscribeToChatChannels(
      userId: userId,
      onData: (chatChannels) {
        _setChatChannels(chatChannels);
        _setLoading(false);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (error) {
        _setErrorMessage(error);
        _setLoading(false);
      },
    );

    return completer.future;
  }

  /// 채널 구독 취소
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

  /// 채널 차단
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
      notifyListeners();
    } else {
      _setErrorMessage('채널 차단 실패');
    }
    _setLoading(false);
  }

  /// 채널 삭제
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
