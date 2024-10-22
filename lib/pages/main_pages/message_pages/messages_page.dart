import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:all_in_one/pages/main_pages/message_pages/friends_page.dart';
import 'package:all_in_one/pages/main_pages/message_pages/file_uploader.dart';
import 'package:all_in_one/pages/main_pages/message_pages/ChatBubble.dart';
import 'package:all_in_one/pages/main_pages/message_pages/message_sender.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _controller =
      TextEditingController(); // Text box control
  final FileUploader fileUploader = FileUploader();
  final MessageSender messageSender = MessageSender();
  bool _isRecording = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fileUploader.initRecorder();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    fileUploader.dispose();
    super.dispose();
  }

  void _startRecording() async {
    await fileUploader.startRecording();
    setState(() {
      _isRecording = true;
    });
  }

  void _stopRecording() async {
    await fileUploader.stopRecordingAndUpload();
    setState(() {
      _isRecording = false;
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    await messageSender.sendMessage(
        text, FirebaseAuth.instance.currentUser!.uid);
    _controller.clear();

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Messages",
            style:
                TextStyle(color: Theme.of(context).colorScheme.inversePrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FriendsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('isPrivate', isEqualTo: false)
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (snapshot.hasData) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());

                  return ListView(
                    controller: _scrollController,
                    reverse: false,
                    children:
                        snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data =
                          document.data() as Map<String, dynamic>;
                      return ChatBubble(
                        isSender: data['sender'] ==
                            FirebaseAuth.instance.currentUser?.uid,
                        message: data['text'],
                        senderName: data['senderName'] ?? 'Unknown',
                        senderAvatar: data['senderAvatar'] ?? '',
                      );
                    }).toList(),
                  );
                } else {
                  return const Center(child: Text("No data available"));
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () => fileUploader.pickFileAndUpload(),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
