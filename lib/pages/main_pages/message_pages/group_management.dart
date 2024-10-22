import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../components/text_field.dart';

class GroupManagement {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  void createGroupDialog(
      BuildContext context, TextEditingController groupNameController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.background,
          title: Text(
            'Create New Group',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          content: MyTextField(
            controller: groupNameController,
            hintText: 'Name',
            obscureText: false,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Create',
                style: TextStyle(
                  color: Colors.green,
                ),
              ),
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

      firestore
          .collection('friends')
          .doc(currentUser.uid)
          .collection('userGroups')
          .doc(groupRef.id)
          .set({
        'name': finalGroupName,
        'avatar': "default_icon",
        'members': [currentUser.uid],
      });
    }
  }

  void showLeaveGroupDialog(
      BuildContext context, String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.background,
          title: Text(
            'Leave Group',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to leave the group "$groupName"?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                leaveGroup(groupId);
                Navigator.of(context).pop();
              },
              child: Text('Leave'),
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

      firestore
          .collection('friends')
          .doc(currentUser.uid)
          .collection('userGroups')
          .doc(groupId)
          .delete();
    }
  }

  void showRemarkDialogForGroup(
      BuildContext context, String groupId, String currentRemark) {
    TextEditingController remarkController =
        TextEditingController(text: currentRemark);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.background,
          title: Text('Set Group Remark', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary,),),
          content: MyTextField(
            controller: remarkController,
            hintText: 'Enter group remark',
            obscureText: false,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary,),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save', style: TextStyle(color: Colors.green),),
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
