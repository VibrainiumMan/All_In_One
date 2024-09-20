import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String currentUserId = currentUser.uid;
      String friendId = await getUserIdFromName(senderName);

      await FirebaseFirestore.instance
          .collection('friends')
          .doc(currentUserId)
          .collection('userFriends')
          .doc(friendId)
          .set({
        'name': senderName,
        'addedOn': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('friends')
          .doc(friendId)
          .collection('userFriends')
          .doc(currentUserId)
          .set({
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
            mainAxisAlignment: widget.isSender
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!widget.isSender)
                GestureDetector(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: const Text('Add Friend'),
                              content: Text(
                                  'Do you want to add ${widget.senderName} as your friend?'),
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
                                    addFriend(widget.senderName);
                                    Navigator.of(context).pop();
                                  },
                                )
                              ],
                            ));
                  },
                  child: CircleAvatar(
                    backgroundImage: widget.senderAvatar.isNotEmpty
                        ? NetworkImage(widget.senderAvatar)
                        : null,
                    child: widget.senderAvatar.isEmpty
                        ? const Icon(Icons.person)
                        : null,
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
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.isSender
                            ? Colors.blue[100]
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(widget.message),
                    ),
                  ],
                ),
              ),
              if (widget.isSender)
                CircleAvatar(
                  backgroundImage: widget.senderAvatar.isNotEmpty
                      ? NetworkImage(widget.senderAvatar)
                      : null,
                  child: widget.senderAvatar.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
