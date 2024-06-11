import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat/features/chat/view_models/chat_channel_view_model.dart';
import 'package:flutter_chat/features/chat/view_models/chat_message_view_model.dart';
import 'package:flutter_chat/features/chat/views/chat_channel_list_screen.dart';
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
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _chatUserIdController = TextEditingController();
  String? currentUserId;

  @override
  void initState() {
    super.initState();
  }

  void setCurrentUser(String userId) {
    setState(() {
      currentUserId = userId;
    });
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _chatUserIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatChannelViewModel = Provider.of<ChatChannelViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meemong Chat'),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  TextField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      labelText: '로그인할 userId를 입력해주세요.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (_userIdController.text.isNotEmpty) {
                        setCurrentUser(_userIdController.text);
                      }
                    },
                    child: const Text('로그인하기'),
                  ),
                  const SizedBox(height: 20),
                  if (currentUserId == null)
                    const Text('로그인할 유저를 선택해주세요.')
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("현재 로그인한 유저: $currentUserId"),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _chatUserIdController,
                          decoration: const InputDecoration(
                            labelText: '채팅방을 생성할 userId를 입력해주세요.',
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            final chatUserId = _chatUserIdController.text;
                            if (chatUserId.isNotEmpty &&
                                currentUserId != null) {
                              final chatChannelViewModel =
                                  Provider.of<ChatChannelViewModel>(context,
                                      listen: false);
                              await chatChannelViewModel.createChannel(
                                sendUserId: currentUserId!,
                                receiveUserId: chatUserId,
                              );
                            }
                          },
                          child: const Text('채팅 시작하기'),
                        ),
                        const SizedBox(height: 20),
                        ListTile(
                          title: const Text('채팅방 리스트'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatChannelListScreen(
                                  userId: currentUserId!,
                                ),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
