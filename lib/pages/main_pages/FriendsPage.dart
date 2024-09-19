import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'messages_page.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  TextEditingController searchController = TextEditingController();
  TextEditingController groupNameController = TextEditingController();

  final StreamController<List<DocumentSnapshot>> _controller = StreamController<List<DocumentSnapshot>>.broadcast();
  Stream<List<DocumentSnapshot>>? combinedStream;

  @override
  void initState() {
    super.initState();
    combinedStream = _controller.stream;
    combineData();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void combineData() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    Stream<QuerySnapshot> friendsStream = FirebaseFirestore.instance
        .collection('friends')
        .doc(currentUser.uid)
        .collection('userFriends')
        .snapshots();

    Stream<QuerySnapshot> groupsStream = FirebaseFirestore.instance
        .collection('friends')
        .doc(currentUser.uid)
        .collection('userGroups')
        .snapshots();

    friendsStream.listen((friendSnapshot) {
      groupsStream.listen((groupSnapshot) {
        List<DocumentSnapshot> combinedDocs = [];
        combinedDocs.addAll(friendSnapshot.docs);
        combinedDocs.addAll(groupSnapshot.docs);
        _controller.add(combinedDocs); // 新代码：向 StreamController 添加数据
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Friends'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _addFriendByEmail(searchController.text.trim()),
          ),
          IconButton(
            icon: Icon(Icons.group_add),
            color: Colors.blue,
            onPressed: () => _createGroupDialog(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search for new friends by email',
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                  },
                ),
              ),
              onSubmitted: (value) => _addFriendByEmail(value),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: combinedStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                //
                // snapshot.data!.forEach((doc) {
                //   Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                //   print("Debug: Document data - $data");
                // });

                return ListView(
                  children: snapshot.data!.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    bool isGroup = data.containsKey('members');
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: isGroup ? Icon(Icons.group) : Icon(Icons.person),
                      ),
                      title: Text(data['remark'] ?? data['name'] ?? 'no name provided'),
                      subtitle: isGroup ? null : Text(data['email'] ?? ''),
                      onTap: () {
                        print(data);
                        String displayName = data['remark'] ?? data['name'] ?? 'Unknown';
                        if (isGroup) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChatPage(
                                  groupId: doc.id,
                                  groupName: displayName,
                              ),
                            ),
                          );
                        }
                        else {
                          _startChat(
                              doc.id,
                              displayName,
                              data['avatar'] ?? 'defaultAvatar'
                          );
                        }
                      },
                      trailing: () {
                        if (isGroup) {
                          return IconButton(
                            icon: Icon(Icons.exit_to_app, color: Colors.red),
                            onPressed: () {
                              _showLeaveGroupDialog(doc.id, data['name'] ?? 'Unnamed Group');
                            },
                          );
                        } else {
                          return IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteFriendDialog(doc.id, data['name'] ?? 'Unknown');
                            },
                          );
                        }
                      }(),
                      onLongPress: () {
                        if (isGroup) {
                          _showRemarkDialogForGroup(
                              doc.id, data['remark'] ?? data['name'] ?? '');
                        } else {
                          _showRemarkDialog(
                              doc.id, data['remark'] ?? data['name'] ?? '');
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _createGroupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create New Group'),
          content: TextField(
            controller: groupNameController,
            decoration: InputDecoration(hintText: "Enter group name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Create'),
              onPressed: () {
                _createGroup(groupNameController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // create group
  void _createGroup(String groupName) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    String finalGroupName = groupName.isNotEmpty ? groupName : "New Group";
    String defaultAvatar = "default_icon";

    if (currentUser != null) {
      DocumentReference groupRef = FirebaseFirestore.instance.collection('groups').doc();
      groupRef.set({
        'name': finalGroupName,
        'avatar': defaultAvatar,
        'members': [currentUser.uid],
        'createdOn': FieldValue.serverTimestamp(),
      });

      FirebaseFirestore.instance.collection('friends').doc(currentUser.uid).collection('userGroups').doc(groupRef.id).set({
        'name': finalGroupName,
        'avatar': defaultAvatar,
        'members':  [currentUser.uid],
      });
    }
  }

  // set remark
  void _showRemarkDialog(String id, String currentRemark) {
    TextEditingController remarkController = TextEditingController(text: currentRemark);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set Remark'),
          content: TextField(
            controller: remarkController,
            decoration: InputDecoration(hintText: "Enter remark name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                _saveRemark(id, remarkController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _saveRemark(String id, String remark) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('friends')
          .doc(currentUser.uid)
          .collection('userFriends')
          .doc(id)
          .update({
        'remark': remark,
      });
    }
  }

  // set group remark
  void _showRemarkDialogForGroup(String id, String currentRemark) {
    TextEditingController remarkController = TextEditingController(text: currentRemark);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set Group Remark'),
          content: TextField(
            controller: remarkController,
            decoration: InputDecoration(hintText: "Enter group remark"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                _saveGroupRemark(id, remarkController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _saveGroupRemark(String id, String remark) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('friends')
          .doc(currentUser.uid)
          .collection('userGroups')
          .doc(id)
          .update({
        'remark': remark,
      });
    }
  }

  // add friend by email
  void _addFriendByEmail(String email) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    var users = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();

    if (users.docs.isNotEmpty) {
      var friendData = users.docs.first.data();
      String friendId = users.docs.first.id;
      String friendName = friendData['name'] ?? 'Unknown';
      String friendEmail = friendData['email'] ?? 'Unknown';


      if (currentUser != null && friendId != currentUser.uid) {
        FirebaseFirestore.instance.collection('friends').doc(currentUser.uid).collection('userFriends').doc(friendId).set({
          'name': friendName,
          'email': friendEmail,
          'addedOn': FieldValue.serverTimestamp(),
        });

        FirebaseFirestore.instance.collection('friends').doc(friendId).collection('userFriends').doc(currentUser.uid).set({
          'name': currentUser.displayName ?? currentUser.email,
          'email': currentUser.email,
          'addedOn': FieldValue.serverTimestamp(),
        });
      }
    } else {
      print("No user found with that email");
    }
  }

  // remove friend
  void _showDeleteFriendDialog(String friendId, String friendName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Friend'),
          content: Text('Are you sure you want to remove $friendName from your friends list?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                _removeFriend(friendId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _removeFriend(String friendId) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('friends')
          .doc(currentUser.uid)
          .collection('userFriends')
          .doc(friendId)
          .delete();

      FirebaseFirestore.instance
          .collection('friends')
          .doc(friendId)
          .collection('userFriends')
          .doc(currentUser.uid)
          .delete();
    }
  }

  // leave group
  void _showLeaveGroupDialog(String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Leave Group'),
          content: Text('Are you sure you want to leave the group "$groupName"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Leave'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                _leaveGroup(groupId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _leaveGroup(String groupId) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .update({
        'members': FieldValue.arrayRemove([currentUser.uid]),
      });

      FirebaseFirestore.instance
          .collection('friends')
          .doc(currentUser.uid)
          .collection('userGroups')
          .doc(groupId)
          .delete();
    }
  }

  // chat func
  void _startChat(String friendId, String friendName, String friendAvatar) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
            peerId: friendId,
            peerAvatar: friendAvatar,
            peerName: friendName,
        ),
      ),
    );
  }
}

// chat page
class ChatPage extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String peerAvatar;

  ChatPage({required this.peerId, required this.peerName, required this.peerAvatar});

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
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, senderSnapshot) {
                if (senderSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (senderSnapshot.hasError) {
                  return Text("Error: ${senderSnapshot.error}");
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('peer_messages')
                      .where('senderId', isEqualTo: widget.peerId)
                      .where('receiverId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, receiverSnapshot) {
                    if (receiverSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (receiverSnapshot.hasError) {
                      return Text("Error: ${receiverSnapshot.error}");
                    }

                    List<QueryDocumentSnapshot> allMessages = [];
                    if (senderSnapshot.hasData) {
                      allMessages.addAll(senderSnapshot.data!.docs);
                    }
                    if (receiverSnapshot.hasData) {
                      allMessages.addAll(receiverSnapshot.data!.docs);
                    }

                    allMessages.sort((a, b) =>
                        (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp));

                    if (allMessages.isEmpty) {
                      return Center(child: Text("No messages"));
                    }

                    return ListView(
                      padding: EdgeInsets.all(10),
                      children: allMessages.map((doc) {
                        return ListTile(
                          title: Align(
                            alignment: doc['senderId'] ==
                                FirebaseAuth.instance.currentUser?.uid
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: doc['senderId'] ==
                                    FirebaseAuth.instance.currentUser?.uid
                                    ? Colors.blue[100]
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(doc['text']),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  child: Icon(Icons.send),
                  elevation: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Group chat page
class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  GroupChatPage({required this.groupId, required this.groupName});

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();

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

      FirebaseFirestore.instance.collection('group_messages').add({
        'text': text,
        'sender': user.uid,
        'senderName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat in ${widget.groupName}'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _addNewMember(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('group_messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  return ListView(
                    reverse: false,
                    children: snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic> data = document.data() as Map<String, dynamic>;

                      return ChatBubble(
                        isSender: data['sender'] == FirebaseAuth.instance.currentUser?.uid,
                        message: data['text'] ?? '',
                        senderName: data['senderName'] ?? 'Unknown',
                        senderAvatar: data['senderAvatar'] ?? '',
                      );
                    }).toList(),
                  );
                } else {
                  return Center(child: Text("No messages"));
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addNewMember() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController emailController = TextEditingController();
        return AlertDialog(
          title: Text('Add New Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: "Enter user's email",
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () => _findAndAddUser(emailController.text.trim()),
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

      var groupRef = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
      var groupSnapshot = await groupRef.get();

      if (groupSnapshot.exists && !(groupSnapshot.data()!['members'] as List).contains(userId)) {
        await groupRef.update({
          'members': FieldValue.arrayUnion([userId])
        });

        // await groupRef.collection('members').doc(userId).set({
        //   'uid': userId,
        //   'addedOn': FieldValue.serverTimestamp(),
        // });

        await FirebaseFirestore.instance.collection('friends').doc(userId).collection('userGroups').doc(widget.groupId).set({
          'avatar': groupSnapshot.data()!['avatar'],
          'members': groupSnapshot.data()!['members'],
          'groupName': groupSnapshot.data()!['name'],
          // 'joinedOn': FieldValue.serverTimestamp(),
        });

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Member added successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User is already in the group')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No user found with that email')));
    }
  }
}