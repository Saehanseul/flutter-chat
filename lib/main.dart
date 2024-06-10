import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/features/chat/view_models/chat_channel_view_model.dart';
import 'package:flutter_chat/features/chat/view_models/chat_message_view_model.dart';
import 'package:flutter_chat/features/chat/views/chat_detail_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HardwareKeyboard.instance.clearState();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatChannelViewModel()),
        ChangeNotifierProvider(create: (_) => ChatMessageViewModel()),
      ],
      child: MaterialApp(
        title: 'flutter chat',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const App(),
      ),
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<App> {
  final tempUser1 = {
    'id': 'user1',
    'name': 'user1',
  };
  final tempUser2 = {
    'id': 'user2',
    'name': 'user2',
  };

  Map<String, String>? currentUser;

  @override
  void initState() {
    super.initState();
  }

  void setCurrentUser(Map<String, String> user) {
    setState(() {
      currentUser = user;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final chatChannelViewModel =
            Provider.of<ChatChannelViewModel>(context, listen: false);
        chatChannelViewModel.fetchChatChannels(currentUser!['id']!);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatChannelViewModel = Provider.of<ChatChannelViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meemong Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => setCurrentUser(tempUser1),
                    child: const Text('tempUser1 로그인'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => setCurrentUser(tempUser2),
                    child: const Text('tempUser2 로그인'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (currentUser == null)
                const Text('로그인할 유저를 선택해주세요.')
              else
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("현재 로그인한 유저: ${currentUser!['name']}"),
                      if (chatChannelViewModel.isLoading)
                        const CircularProgressIndicator()
                      else
                        ElevatedButton(
                          onPressed: () async {
                            await chatChannelViewModel.createChannel(
                              sendUserId: currentUser!['id']!,
                              receiveUserId:
                                  currentUser!['id'] == tempUser1['id']
                                      ? tempUser2['id']!
                                      : tempUser1['id']!,
                            );
                          },
                          child: const Text('채널 생성'),
                        ),
                      if (chatChannelViewModel.errorMessage.isNotEmpty)
                        Text(
                          chatChannelViewModel.errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: chatChannelViewModel.chatChannels.length,
                          itemBuilder: (context, index) {
                            final channel =
                                chatChannelViewModel.chatChannels[index];

                            List<String> participants =
                                List<String>.from(channel['participantsIds']);
                            String otherUserId = participants
                                .firstWhere((id) => id != currentUser!['id']);
                            String otherUserName =
                                otherUserId == tempUser1['id']
                                    ? tempUser1['name']!
                                    : tempUser2['name']!;
                            return Slidable(
                              key: Key(channel['channelId']),
                              endActionPane: ActionPane(
                                motion: const DrawerMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (context) {
                                      // 핀 고정 로직을 여기에 추가하세요
                                    },
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    icon: Icons.push_pin,
                                    label: '핀고정',
                                  ),
                                  SlidableAction(
                                    onPressed: (context) {
                                      setState(() {
                                        chatChannelViewModel.deleteChannel(
                                            channelId: channel['channelId']);
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
                                subtitle:
                                    Text('${channel['lastMessage'] ?? ''}'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailScreen(
                                        channelId: channel['channelId'],
                                        otherUserName: otherUserName,
                                        sendUserId: currentUser!['id']!,
                                        receiveUserId: otherUserId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              if (chatChannelViewModel.errorMessage.isNotEmpty)
                Text(
                  chatChannelViewModel.errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
