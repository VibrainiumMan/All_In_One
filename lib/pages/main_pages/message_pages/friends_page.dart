import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:all_in_one/pages/main_pages/message_pages/friend_management.dart';
import 'package:all_in_one/pages/main_pages/message_pages/group_management.dart';
import 'package:all_in_one/pages/main_pages/message_pages/ChatPage.dart';
import 'package:all_in_one/pages/main_pages/message_pages/group_chat_page.dart';

import '../../../components/text_field.dart';

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
          backgroundColor: Theme.of(context).colorScheme.background,
          title: const Text('Add Friend by Email'),
          content: MyTextField(
            controller: emailController,
            hintText: 'Email',
            obscureText: false,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.green,
                ),
              ),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8CAEB7),
        title: Text(
          'My Friends',
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontSize: 25,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            onPressed: () => _showEmailDialog(context),
          ),
          IconButton(
            icon: Icon(
              Icons.group_add,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
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
                  backgroundColor: const Color(0xFF8CAEB7),
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
