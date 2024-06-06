import 'package:flutter/material.dart';
import 'package:flutter_chat/features/chat/view_models/chat_message_view_model.dart';
import 'package:provider/provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String channelId;
  final String otherUserName;
  final String sendUserId;
  final String receiveUserId;

  const ChatDetailScreen({
    super.key,
    required this.channelId,
    required this.otherUserName,
    required this.sendUserId,
    required this.receiveUserId,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // // 화면이 처음 로드될 때 메시지 목록을 가져옵니다.
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<ChatMessageViewModel>(context, listen: false)
    //       .fetchMessages(widget.channelId);
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatMessageViewModel>(context, listen: false)
          .subscribeToMessages(widget.channelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.otherUserName}'),
      ),
      body: Column(
        children: [
          // 메시지 목록은 여기에서 구현할 수 있습니다.
          Expanded(
            child: Consumer<ChatMessageViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.errorMessage.isNotEmpty) {
                  return Center(child: Text(viewModel.errorMessage));
                }

                if (viewModel.messages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  itemCount: viewModel.messages.length,
                  itemBuilder: (context, index) {
                    final message = viewModel.messages[index];
                    return ListTile(
                      title: Text(message['message'] ?? ''),
                      subtitle: Text(message['userId'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Enter message',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      if (_messageController.text.isNotEmpty) {
                        final viewModel = Provider.of<ChatMessageViewModel>(
                            context,
                            listen: false);
                        await viewModel.sendMessage(
                          channelId: widget.channelId,
                          sendUserId: widget.sendUserId,
                          receiveUserId: widget.receiveUserId,
                          message: _messageController.text,
                        );
                        _messageController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (context.watch<ChatMessageViewModel>().isLoading)
            const LinearProgressIndicator(),
          if (context.watch<ChatMessageViewModel>().errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                context.watch<ChatMessageViewModel>().errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
