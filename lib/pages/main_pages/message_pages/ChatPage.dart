import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ChatBubble.dart';

class ChatPage extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String peerAvatar;

  const ChatPage({required this.peerId, required this.peerName, required this.peerAvatar, Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      FirebaseFirestore.instance.collection('peer_messages').add({
        'text': _messageController.text,
        'senderId': FirebaseAuth.instance.currentUser?.uid,
        'receiverId': widget.peerId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.peerName}'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('peer_messages')
                  .where('senderId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('receiverId', isEqualTo: widget.peerId)
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, senderSnapshot) {
                if (senderSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (senderSnapshot.hasError) {
                  return Text("Error: ${senderSnapshot.error}");
                }

                return ListView(
                  children: senderSnapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    return ChatBubble(
                      isSender: data['senderId'] == FirebaseAuth.instance.currentUser?.uid,
                      message: data['text'],
                      senderName: widget.peerName,
                      senderAvatar: widget.peerAvatar,
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                  ),
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