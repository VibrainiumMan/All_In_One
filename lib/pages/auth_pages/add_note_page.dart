import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddNotePage extends StatefulWidget {
  const AddNotePage({Key? key}) : super(key: key);

  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context); // Access theme for colour adaptation

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Note"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Title Input Field with Rectangle Border
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded Rectangle
                  borderSide: const BorderSide(
                    color: Colors.grey, // Border color
                    width: 1.0, // Border width
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Content Input Field
            Expanded(
              child: TextFormField(
                controller: _contentController,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: "Content",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0), // Rounded Rectangle
                    borderSide: const BorderSide(
                      color: Colors.grey, // Border color
                      width: 1.0, // Border width
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save note button to trigger saving functionality
            ElevatedButton(
              onPressed: _saveNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary, // Bg colour
                foregroundColor: theme.brightness == Brightness.light
                    ? Colors.black // Black text in light mode
                    : Colors.white, // White text in dark mode
              ),
              child: const Text("Save Note"),
            ),
          ],
        ),
      ),
    );
  }

  // Function to save note in firebase
  Future<void> _saveNote() async {
    final title = _titleController.text;
    final content = _contentController.text;
    final user = FirebaseAuth.instance.currentUser;

    // Validate if title and content aren't empty and the user is logged in
    if (title.isNotEmpty && content.isNotEmpty && user != null) {
      try {
        // Save the note to firestore
        await FirebaseFirestore.instance.collection('notes').add({
          'title': title,
          'content': content,
          'owner': user.email,
          'createdAt': Timestamp.now(),
        });
        Navigator.pop(context); // Return to previous screen after saving
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving note: $e")),
        );
      }
    } else {
      // Show a message if required feilds are missing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
    }
  }
}
