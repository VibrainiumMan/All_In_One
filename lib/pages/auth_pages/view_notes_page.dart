import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:all_in_one/pages/auth_pages/edit_note_page.dart';
import 'package:all_in_one/pages/auth_pages/note_detail_page.dart';
import 'package:all_in_one/pages/auth_pages/add_note_page.dart';
import 'package:zefyrka/zefyrka.dart';

class ViewNotesPage extends StatefulWidget {
  const ViewNotesPage({Key? key}) : super(key: key);

  @override
  _ViewNotesPageState createState() => _ViewNotesPageState();
}

class _ViewNotesPageState extends State<ViewNotesPage> {
  String? selectedFolderId;
  String? selectedFolderName;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectedFolderId != null) {
          setState(() {
            selectedFolderId = null;
            selectedFolderName = null;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(selectedFolderName ?? "My Notes"),
          actions: [
            IconButton(
              icon: const Icon(Icons.create_new_folder),
              onPressed: () {
                _createFolderDialog(context);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Display folders for organizing notes
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('folders')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No folders available."));
                }

                final folders = snapshot.data!.docs;

                return Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      var folder = folders[index];
                      String folderName = folder['folderName'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFolderId = folder.id;
                            selectedFolderName = folderName;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: selectedFolderId == folder.id
                                ? Colors.blue
                                : Colors.grey[300],
                          ),
                          child: Column(
                            children: [
                              Text(
                                folderName,
                                style: const TextStyle(color: Colors.white),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                    onPressed: () {
                                      _renameFolderDialog(context, folder.id, folderName);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _confirmDeleteFolder(context, folder.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            // Display notes in the selected folder
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: selectedFolderId != null
                    ? FirebaseFirestore.instance
                    .collection('notes')
                    .where('owner', isEqualTo: FirebaseAuth.instance.currentUser?.email)
                    .where('folderId', isEqualTo: selectedFolderId)
                    .snapshots()
                    : FirebaseFirestore.instance
                    .collection('notes')
                    .where('owner', isEqualTo: FirebaseAuth.instance.currentUser?.email)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No notes available."));
                  }

                  final notes = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      var noteDoc = notes[index];
                      var note = noteDoc.data() as Map<String, dynamic>;
                      String title = note['title'] ?? 'No Title';
                      String content = note['content'] ?? '[]';

                      var createdAt = note['createdAt'] != null
                          ? note['createdAt'].toDate()
                          : null;

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          title: Text(title),
                          subtitle: _buildNotePreview(content),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                createdAt != null
                                    ? "${createdAt.day}/${createdAt.month}/${createdAt.year}"
                                    : "Unknown Date",
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditNotePage(noteDoc.id, note),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.green),
                                onPressed: () {
                                  _moveNoteToFolder(context, noteDoc.id);
                                },
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _confirmDelete(context, noteDoc.id);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NoteDetailPage(note: note),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );

                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddNotePage()),
            );
          },
          child: const Icon(Icons.add),
          tooltip: 'Add Note',
        ),
      ),
    );
  }

  Widget _buildNotePreview(String content) {
    try {
      final jsonContent = jsonDecode(content);
      final document = NotusDocument.fromJson(jsonContent);
      final plainText = document.toPlainText();

      return Text(
        plainText.length > 50 ? plainText.substring(0, 50) + '...' : plainText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    } catch (e) {
      print('Error parsing note content: $e');
      return const Text('Error displaying note preview');
    }
  }

  void _createFolderDialog(BuildContext context) {
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
                _createFolder(folderController.text);
                Navigator.of(context).pop();
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _createFolder(String folderName) async {
    if (folderName.isNotEmpty) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('folders').add({
          'folderName': folderName,
          'userId': userId,
          'createdAt': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Folder '$folderName' created successfully")),
        );
      }
    }
  }

  void _moveNoteToFolder(BuildContext context, String noteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('folders')
              .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();

            var folders = snapshot.data!.docs;
            return AlertDialog(
              title: const Text("Move to Folder"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: folders.map((folder) {
                  return ListTile(
                    title: Text(folder['folderName']),
                    onTap: () {
                      _moveNoteToSelectedFolder(noteId, folder.id);
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

  void _moveNoteToSelectedFolder(String noteId, String folderId) async {
    await FirebaseFirestore.instance
        .collection('notes')
        .doc(noteId)
        .update({'folderId': folderId});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Note moved to folder")),
    );
  }

  void _renameFolderDialog(BuildContext context, String folderId, String currentName) {
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
                _renameFolder(folderId, folderController.text);
                Navigator.of(context).pop();
              },
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );
  }

  void _renameFolder(String folderId, String newName) async {
    if (newName.isNotEmpty) {
      await FirebaseFirestore.instance.collection('folders').doc(folderId).update({
        'folderName': newName,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Folder renamed to '$newName'")),
      );
    }
  }

  void _confirmDeleteFolder(BuildContext context, String folderId) {
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
                _deleteFolderAndNotes(folderId);
                Navigator.of(context).pop();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _deleteFolderAndNotes(String folderId) async {
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

  void _confirmDelete(BuildContext context, String noteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Note"),
          content: const Text("Are you sure you want to delete this note?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteNote(noteId);
                Navigator.of(context).pop();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await FirebaseFirestore.instance.collection('notes').doc(noteId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete note: $e")),
      );
    }
  }
}
