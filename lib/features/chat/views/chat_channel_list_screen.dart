import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/features/chat/view_models/chat_channel_view_model.dart';
import 'package:flutter_chat/features/chat/views/chat_detail_screen.dart';
import 'package:flutter_chat/utils.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

class ChatChannelListScreen extends StatefulWidget {
  final String userId;

  const ChatChannelListScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ChatChannelListScreen> createState() => _ChatChannelListScreenState();
}

class _ChatChannelListScreenState extends State<ChatChannelListScreen> {
  ChatChannelViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      _viewModel = Provider.of<ChatChannelViewModel>(context, listen: false);
      Future.microtask(
          () => _viewModel!.subscribeToChatChannels(widget.userId));
    }
  }

  @override
  void dispose() {
    _viewModel?.unsubscribeFromChatChannels();
    super.dispose();
  }

  // Timestamp 포맷팅
  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateFormat formatter = DateFormat('MM-dd HH:mm');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final chatChannelViewModel = Provider.of<ChatChannelViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Channels'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              if (chatChannelViewModel.isLoading)
                const CircularProgressIndicator()
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: chatChannelViewModel.chatChannels.length,
                    itemBuilder: (context, index) {
                      final channel = chatChannelViewModel.chatChannels[index];
                      List<String> participants =
                          List<String>.from(channel['participantsIds']);
                      String otherUserId =
                          participants.firstWhere((id) => id != widget.userId);
                      String otherUserName = otherUserId; // 필요 시 이름 맵핑 로직 추가

                      bool isPinned =
                          channel['pinnedBy']?.containsKey(widget.userId) ??
                              false;

                      return Slidable(
                        key: Key(channel['channelId']),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                if (isPinned) {
                                  chatChannelViewModel.unpinChannel(
                                      channel['channelId'], widget.userId);
                                } else {
                                  chatChannelViewModel.pinChannel(
                                      channel['channelId'], widget.userId);
                                }
                              },
                              backgroundColor:
                                  isPinned ? Colors.green : Colors.blue,
                              foregroundColor: Colors.white,
                              icon: isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              label: isPinned ? '해제' : '핀고정',
                            ),
                            SlidableAction(
                              onPressed: (context) {
                                setState(() {
                                  chatChannelViewModel
                                      .deleteChannel(channel['channelId']);
                                  chatChannelViewModel.chatChannels
                                      .removeAt(index);
                                });
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: '삭제',
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(otherUserName),
                          subtitle: Text('${channel['lastMessage'] ?? ''}'),
                          trailing: SizedBox(
                            width: 120,
                            height: 40,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  channel['updatedAt'] != null
                                      ? _formatTimestamp(channel['updatedAt'])
                                      : '',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                if (channel['unreadCounts'][widget.userId] > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: badges.Badge(
                                      badgeContent: Text(
                                        '${channel['unreadCounts'][widget.userId]}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      badgeStyle: const badges.BadgeStyle(
                                        badgeColor: Colors.red,
                                        padding: EdgeInsets.all(6),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          onTap: () {
                            bool isBlocked =
                                isAnyUserBlocked(channel['blockedUsers']);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  channelId: channel['channelId'],
                                  otherUserName: otherUserName,
                                  sendUserId: widget.userId,
                                  receiveUserId: otherUserId,
                                  isBlocked: isBlocked,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              if (chatChannelViewModel.errorMessage.isNotEmpty)
                Text(
                  chatChannelViewModel.errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
