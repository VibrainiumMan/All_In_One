import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FolderManager {
  void createFolder(BuildContext context) {
    TextEditingController folderController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Create Folder"),
          content: TextField(
            controller: folderController,
            decoration: const InputDecoration(hintText: "Folder Name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _createFolder(folderController.text, context);
                Navigator.of(context).pop();
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _createFolder(String folderName, BuildContext context) async {
    if (folderName.isNotEmpty) {
      await FirebaseFirestore.instance.collection('folders').add({
        'folderName': folderName,
        'createdAt': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Folder '$folderName' created successfully")),
      );
    }
  }

  void renameFolder(BuildContext context, String folderId, String currentName) {
    TextEditingController folderController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rename Folder"),
          content: TextField(
            controller: folderController,
            decoration: const InputDecoration(hintText: "New Folder Name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _renameFolder(folderId, folderController.text, context);
                Navigator.of(context).pop();
              },
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );
  }

  void _renameFolder(String folderId, String newName, BuildContext context) async {
    if (newName.isNotEmpty) {
      await FirebaseFirestore.instance.collection('folders').doc(folderId).update({
        'folderName': newName,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Folder renamed to '$newName'")),
      );
    }
  }

  void confirmDeleteFolder(BuildContext context, String folderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Folder"),
          content: const Text("Are you sure you want to delete this folder and all its notes?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteFolderAndNotes(folderId, context);
                Navigator.of(context).pop();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _deleteFolderAndNotes(String folderId, BuildContext context) async {
    var notes = await FirebaseFirestore.instance
        .collection('notes')
        .where('folderId', isEqualTo: folderId)
        .get();

    for (var note in notes.docs) {
      await note.reference.delete();
    }

    await FirebaseFirestore.instance.collection('folders').doc(folderId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Folder and its notes deleted successfully")),
    );
  }

  void moveNoteToFolder(BuildContext context, String noteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('folders').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return CircularProgressIndicator();

            var folders = snapshot.data!.docs;
            return AlertDialog(
              title: const Text("Move to Folder"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: folders.map((folder) {
                  return ListTile(
                    title: Text(folder['folderName']),
                    onTap: () {
                      _moveNoteToSelectedFolder(noteId, folder.id, context);
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  void _moveNoteToSelectedFolder(String noteId, String folderId, BuildContext context) async {
    await FirebaseFirestore.instance.collection('notes').doc(noteId).update({
      'folderId': folderId,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Note moved to folder")),
    );
  }
}
