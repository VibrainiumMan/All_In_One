import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendManagement {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Stream<List<DocumentSnapshot>> getCombinedStream() {
    final User? currentUser = auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    final Stream<QuerySnapshot> friendsStream = firestore
        .collection('friends')
        .doc(currentUser.uid)
        .collection('userFriends')
        .snapshots();

    final Stream<QuerySnapshot> groupsStream = firestore
        .collection('friends')
        .doc(currentUser.uid)
        .collection('userGroups')
        .snapshots();

    return friendsStream.asyncExpand((friendsSnapshot) {
      return groupsStream.map((groupsSnapshot) {
        List<DocumentSnapshot> combinedDocs = [];
        combinedDocs.addAll(friendsSnapshot.docs);
        combinedDocs.addAll(groupsSnapshot.docs);
        return combinedDocs;
      });
    });
  }

  void addFriendByEmail(
      String email, BuildContext context, Function updateUI) async {
    final User? currentUser = auth.currentUser;
    if (currentUser == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    try {
      final users = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (users.docs.isNotEmpty) {
        final friendData = users.docs.first.data();
        final friendId = users.docs.first.id;
        final friendName = friendData['name'] ?? 'Unknown';

        if (friendId != currentUser.uid) {
          await firestore
              .collection('friends')
              .doc(currentUser.uid)
              .collection('userFriends')
              .doc(friendId)
              .set({
            'name': friendName,
            'email': email,
            'addedOn': FieldValue.serverTimestamp(),
          });

          await firestore
              .collection('friends')
              .doc(friendId)
              .collection('userFriends')
              .doc(currentUser.uid)
              .set({
            'name': currentUser.displayName ?? 'Unknown',
            'email': currentUser.email,
            'addedOn': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend added successfully')),
          );

          updateUI();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You cannot add yourself as a friend')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found with that email')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding friend: $e')),
      );
    }
  }

  void showDeleteFriendDialog(
      BuildContext context, String friendId, String friendName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Friend'),
          content: Text(
              'Are you sure you want to remove $friendName from your friends list?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                removeFriend(friendId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void removeFriend(String friendId) {
    final User? currentUser = auth.currentUser;
    if (currentUser == null) return;

    firestore
        .collection('friends')
        .doc(currentUser.uid)
        .collection('userFriends')
        .doc(friendId)
        .delete();
    firestore
        .collection('friends')
        .doc(friendId)
        .collection('userFriends')
        .doc(currentUser.uid)
        .delete();
  }

  void showRemarkDialog(BuildContext context, String id, String currentRemark,
      Function updateUI) {
    TextEditingController remarkController =
        TextEditingController(text: currentRemark);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Friend Remark'),
          content: TextField(
            controller: remarkController,
            decoration: const InputDecoration(hintText: "Enter remark name"),
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
                saveRemark(id, remarkController.text).then((_) {
                  updateUI();
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> saveRemark(String id, String remark) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('friends')
          .doc(currentUser.uid)
          .collection('userFriends')
          .doc(id)
          .update({'remark': remark});
    }
  }
}
