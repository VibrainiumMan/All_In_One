import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:all_in_one/pages/main_pages/message_pages/FriendManagement.dart';
import 'package:all_in_one/pages/main_pages/message_pages/GroupManagement.dart';
import 'package:all_in_one/pages/main_pages/message_pages/ChatPage.dart';
import 'package:all_in_one/pages/main_pages/message_pages/GroupChatPage.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController groupNameController = TextEditingController();
  final FriendManagement friendManagement = FriendManagement();
  final GroupManagement groupManagement = GroupManagement();

  @override
  void dispose() {
    searchController.dispose();
    groupNameController.dispose();
    super.dispose();
  }

  void _showEmailDialog(BuildContext context) {
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Friend by Email'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(hintText: "Enter email"),
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
                friendManagement
                    .addFriendByEmail(emailController.text.trim(), context, () {
                  setState(() {});
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showEmailDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () =>
                groupManagement.createGroupDialog(context, groupNameController),
          ),
        ],
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: friendManagement.getCombinedStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              bool isGroup = data.containsKey('members');

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: isGroup
                      ? const Icon(Icons.group)
                      : const Icon(Icons.person),
                ),
                title:
                    Text(data['remark'] ?? data['name'] ?? 'No name provided'),
                subtitle: isGroup ? null : Text(data['email'] ?? ''),
                onTap: () {
                  if (isGroup) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupChatPage(
                          groupId: doc.id,
                          groupName:
                              data['remark'] ?? data['name'] ?? 'Unnamed Group',
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          peerId: doc.id,
                          peerName: data['remark'] ?? data['name'] ?? 'Unknown',
                          peerAvatar: data['avatar'] ?? 'defaultAvatar',
                        ),
                      ),
                    );
                  }
                },
                trailing: IconButton(
                  icon: isGroup
                      ? const Icon(Icons.exit_to_app, color: Colors.red)
                      : const Icon(Icons.delete, color: Colors.red),
                  onPressed: isGroup
                      ? () => groupManagement.showLeaveGroupDialog(
                          context, doc.id, data['name'] ?? 'Unnamed Group')
                      : () => friendManagement.showDeleteFriendDialog(
                          context, doc.id, data['name'] ?? 'Unknown'),
                ),
                onLongPress: () {
                  if (isGroup) {
                    groupManagement.showRemarkDialogForGroup(
                      context,
                      doc.id,
                      data['remark'] ?? data['name'] ?? 'Unknown',
                    );
                  } else {
                    // 修改备注后刷新页面
                    friendManagement.showRemarkDialog(
                      context,
                      doc.id,
                      data['remark'] ?? data['name'] ?? 'Unknown',
                      () {
                        setState(() {});
                      },
                    );
                  }
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
