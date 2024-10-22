import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../components/text_field.dart';
import 'ChatBubble.dart';

class ChatPage extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String peerAvatar;

  const ChatPage(
      {required this.peerId,
      required this.peerName,
      required this.peerAvatar,
      Key? key})
      : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      FirebaseFirestore.instance.collection('peer_messages').add({
        'text': _messageController.text,
        'senderId': FirebaseAuth.instance.currentUser?.uid,
        'receiverId': widget.peerId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8CAEB7),
        title: Text(
          'Chat with ${widget.peerName}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontSize: 25,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('peer_messages')
                  .where('senderId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
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

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView(
                  controller: _scrollController,
                  children: senderSnapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    return ChatBubble(
                      isSender: data['senderId'] ==
                          FirebaseAuth.instance.currentUser?.uid,
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
                  child: MyTextField(
                    controller: _messageController,
                    hintText: 'Send a message',
                    obscureText: false,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).colorScheme.inversePrimary,),
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
