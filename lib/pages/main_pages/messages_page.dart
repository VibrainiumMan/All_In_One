import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'FriendsPage.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _controller = TextEditingController(); // Text box control
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

  void _sendVoiceMessage(String path) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String fileName = path.split('/').last;
      // Create file ref of firebase storage
      Reference storageRef = FirebaseStorage.instance.ref().child('voiceMessages/$fileName');
      // Upload file
      UploadTask uploadTask = storageRef.putFile(File(path));

      try {
        // Waiting upload finished and get download link
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String userName = userSnapshot.get('name');
        String userAvatar = userSnapshot.get('avatar');

        // Update to firestore
        FirebaseFirestore.instance.collection('messages').add({
          'type': 'voice',
          'url': downloadUrl,
          'sender': user.uid,
          'senderName': userName,
          'senderAvatar': userAvatar,
          'timestamp': FieldValue.serverTimestamp(),
          'isPrivate': false,
        });
      } catch (e) {
        print('Error uploading voice message: $e');
      }
    }
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      _sendFileMessage(file.name);
    }
  }

  void _sendFileMessage(String filePath) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String fileName = filePath.split('/').last;
      // Create file ref of firebase storage
      Reference storageRef = FirebaseStorage.instance.ref().child('uploadedFiles/$fileName');
      // Upload file
      UploadTask uploadTask = storageRef.putFile(File(filePath));

      try {
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String userName = userSnapshot.get('name');
        String userAvatar = userSnapshot.get('avatar');

        FirebaseFirestore.instance.collection('messages').add({
          'type': 'file',
          'url': downloadUrl,
          'fileName': fileName,
          'sender': user.uid,
          'senderName': userName,
          'senderAvatar': userAvatar,
          'timestamp': FieldValue.serverTimestamp(),
          'isPrivate': false,
        });
      } catch (e) {
        print('Error uploading file message: $e');
      }
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    final User? user = FirebaseAuth.instance.currentUser;
    if (text.isNotEmpty && user != null) {
      // Waiting upload finished and get download link
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String userName = userSnapshot.get('name');
      String userAvatar = userSnapshot.get('avatar');

      // Update to firestore
      FirebaseFirestore.instance.collection('messages').add({
        'text': text,
        'sender': user.uid,
        'senderName': userName,
        'senderAvatar': userAvatar,
        'timestamp': FieldValue.serverTimestamp(),
        'isPrivate': false,
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
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (snapshot.hasData) {
                  if (snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No messages"));
                  }
                  return ListView(
                    reverse: false,
                    children: snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                      return ChatBubble(
                        isSender: data['sender'] == FirebaseAuth.instance.currentUser?.uid,
                        message: data['text'],
                        senderName: data['senderName'] ?? 'Unknown',
                        senderAvatar: data['senderAvatar'] ?? '',
                      );
                    }).toList(),
                  );
                } else {
                  return Center(child: Text("No data available"));
                }
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

class ChatBubble extends StatefulWidget {
  final bool isSender;
  final String message;
  final String senderName;
  final String senderAvatar;

  const ChatBubble({
    Key? key,
    required this.isSender,
    required this.message,
    required this.senderName,
    required this.senderAvatar,
  }) : super(key: key);

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  Future<void> addFriend(String senderName) async {
    final User? currentUser =FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String currentUserId = currentUser.uid;
      String friendId = await getUserIdFromName(senderName);

      await FirebaseFirestore.instance.collection('friends').doc(currentUserId).collection('userFriends').doc(friendId).set({
        'name': senderName,
        'addedOn': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('friends').doc(friendId).collection('userFriends').doc(currentUserId).set({
        'name': currentUser.displayName ?? currentUser.email,
        'addedOn': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String> getUserIdFromName(String name) async {
    var result = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    return result.docs.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
      child: Column(
        crossAxisAlignment:
        widget.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
            widget.isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!widget.isSender)
                GestureDetector(
                  onTap: () {
                    showDialog(context: context, builder: (context) => AlertDialog(
                      title: Text('Add Friend'),
                      content: Text('Do you want to add ${widget.senderName} as your friend?'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Cancel'),
                          onPressed:() {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('Add'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () {
                            addFriend(widget.senderName);
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: widget.senderAvatar.isNotEmpty
                        ? NetworkImage(widget.senderAvatar)
                        : null,
                    child: widget.senderAvatar.isEmpty ? Icon(Icons.person) : null,
                  ),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.isSender)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          widget.senderName,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.isSender ? Colors.blue[100] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(widget.message),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (widget.isSender)
                CircleAvatar(
                  backgroundImage: widget.senderAvatar.isNotEmpty
                      ? NetworkImage(widget.senderAvatar)
                      : null,
                  child: widget.senderAvatar.isEmpty ? Icon(Icons.person) : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final DateTime timestamp;
  final bool isPrivate;

  Message({
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.timestamp,
    this.isPrivate = false,
  });

  factory Message.fromJson(Map<String, dynamic> data) {
    return Message(
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatar: data['senderAvatar'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
      isPrivate: data['isPrivate'] ?? false,
    );
  }
}
