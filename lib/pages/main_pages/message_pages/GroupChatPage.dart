import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ChatBubble.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatPage(
      {required this.groupId, required this.groupName, Key? key})
      : super(key: key);

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    final text = _messageController.text.trim();
    final User? user = FirebaseAuth.instance.currentUser;
    if (text.isNotEmpty && user != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String userName = userSnapshot.get('name');
      String userAvatar = userSnapshot.get('avatar');

      FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'text': text,
        'sender': user.uid,
        'senderName': userName,
        'senderAvatar': userAvatar,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();

      _scrollToBottom();
    }
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

  void _addNewMember() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Member'),
          content: TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: "Enter user's email",
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                _findAndAddUser(_emailController.text.trim());
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _findAndAddUser(String email) async {
    if (email.isEmpty) {
      return;
    }

    var userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      var userData = userQuery.docs.first;
      var userId = userData.id;

      var groupRef =
          FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
      var groupSnapshot = await groupRef.get();

      if (groupSnapshot.exists &&
          !(groupSnapshot.data()!['members'] as List).contains(userId)) {
        await groupRef.update({
          'members': FieldValue.arrayUnion([userId])
        });

        await FirebaseFirestore.instance
            .collection('friends')
            .doc(userId)
            .collection('userGroups')
            .doc(widget.groupId)
            .set({
          'avatar': groupSnapshot.data()!['avatar'],
          'members': groupSnapshot.data()!['members'],
          'groupName': groupSnapshot.data()!['name'],
        });

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member added successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User is already in the group')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found with that email')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat in Group ${widget.groupName}'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewMember,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }

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
                      message: data['text'] ?? '',
                      senderName: data['senderName'] ?? 'Unknown',
                      senderAvatar: data['senderAvatar'] ?? '',
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
