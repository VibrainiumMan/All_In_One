import 'package:all_in_one/pages/message_pages/group_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _controller =
      TextEditingController(); // Text box control
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? userID = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  void _startRecording() async {
    await _recorder.startRecorder(toFile: 'voice_message.mp4');
    setState(() {
      _isRecording = true;
    });
  }

  void _stopRecording() async {
    final path = await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    if (path != null) {
      _sendVoiceMessage(path);
    }
  }

  void _sendVoiceMessage(String path) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('messages').add({
        'text': 'Voice message sent',
        'path': path,
        'sender': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      _sendFileMessage(file.name);
    }
  }

  void _sendFileMessage(String fileName) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('messages').add({
        'text': 'File sent',
        'fileName': fileName,
        'sender': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    final User? user = FirebaseAuth.instance.currentUser;
    if (text.isNotEmpty && user != null) {
      FirebaseFirestore.instance.collection('messages').add({
        'text': text,
        'sender': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text("Messages",
            style:
                TextStyle(color: Theme.of(context).colorScheme.inversePrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.group),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => GroupChatPage()));
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
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                return ListView(
                  reverse: true,
                  children:
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data()! as Map<String, dynamic>;
                    return ChatBubble(
                      isSender: data['sender'] ==
                          FirebaseAuth.instance.currentUser?.uid,
                      message: data['text'],
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: _pickFile,
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
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage, // send message
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final bool isSender;
  final String message;

  ChatBubble({required this.isSender, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: isSender ? Colors.blue[100] : Colors.grey[200],
          borderRadius: isSender
              ? BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                )
              : BorderRadius.only(
                  topRight: Radius.circular(12),
                  topLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
        ),
        child: Text(message),
      ),
    );
  }
}

class Message {
  final String text;
  final String sender;
  final int timestamp;

  Message({required this.text, required this.sender, required this.timestamp});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'] ?? '',
      sender: json['sender'] ?? 'Unknown',
      timestamp: (json['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }
}
