import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:all_in_one/pages/auth_pages/edit_note_page.dart';
import 'package:all_in_one/pages/auth_pages/note_detail_page.dart';



class ViewNotesPage extends StatefulWidget {
  const ViewNotesPage({Key? key}) : super(key: key);

  @override
  _ViewNotesPageState createState() => _ViewNotesPageState();
}

class _ViewNotesPageState extends State<ViewNotesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
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
              String content = note['content'] ?? 'No Content';

              var createdAt = note['createdAt'] != null
                  ? note['createdAt'].toDate()
                  : null;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(
                    content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Display Created Date
                      Text(
                        createdAt != null
                            ? "${createdAt.day}/${createdAt.month}/${createdAt.year}"
                            : "Unknown Date",
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      // Edit Button
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
                      // Delete Button
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
    );
  }

  // Function to confirm deletion
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
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteNote(noteId);
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // Function to delete note from Firestore
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
