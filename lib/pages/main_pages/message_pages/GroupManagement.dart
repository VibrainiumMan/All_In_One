import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupManagement {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  void createGroupDialog(BuildContext context, TextEditingController groupNameController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Group'),
          content: TextField(
            controller: groupNameController,
            decoration: const InputDecoration(hintText: "Enter group name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                createGroup(groupNameController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void createGroup(String groupName) {
    final User? currentUser = auth.currentUser;
    String finalGroupName = groupName.isNotEmpty ? groupName : "New Group";

    if (currentUser != null) {
      final groupRef = firestore.collection('groups').doc();
      groupRef.set({
        'name': finalGroupName,
        'avatar': "default_icon",
        'members': [currentUser.uid],
        'createdOn': FieldValue.serverTimestamp(),
      });

      firestore.collection('friends').doc(currentUser.uid).collection('userGroups').doc(groupRef.id).set({
        'name': finalGroupName,
        'avatar': "default_icon",
        'members': [currentUser.uid],
      });
    }
  }

  void showLeaveGroupDialog(BuildContext context, String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Group'),
          content: Text('Are you sure you want to leave the group "$groupName"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Leave'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                leaveGroup(groupId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void leaveGroup(String groupId) {
    final User? currentUser = auth.currentUser;
    if (currentUser != null) {
      firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([currentUser.uid]),
      });

      firestore.collection('friends').doc(currentUser.uid).collection('userGroups').doc(groupId).delete();
    }
  }

  void showRemarkDialogForGroup(BuildContext context, String groupId, String currentRemark) {
    TextEditingController remarkController = TextEditingController(text: currentRemark);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Group Remark'),
          content: TextField(
            controller: remarkController,
            decoration: const InputDecoration(hintText: "Enter group remark"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                saveGroupRemark(groupId, remarkController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void saveGroupRemark(String groupId, String remark) {
    final User? currentUser = auth.currentUser;
    if (currentUser != null) {
      firestore
          .collection('friends')
          .doc(currentUser.uid)
          .collection('userGroups')
          .doc(groupId)
          .update({
        'remark': remark,
      });
    }
  }
}