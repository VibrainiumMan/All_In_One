import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditNotePage extends StatefulWidget {
  final String noteId;
  final Map<String, dynamic> note;

  const EditNotePage(this.noteId, this.note, {Key? key}) : super(key: key);

  @override
  _EditNotePageState createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note['title']);
    _contentController = TextEditingController(text: widget.note['content']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Access theme for colour adaptation

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Note"),
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
            ElevatedButton(
              onPressed: _updateNote,
              style: ElevatedButton.styleFrom(
                foregroundColor: theme.brightness == Brightness.light
                    ? Colors.black // Black text in light mode
                    : Colors.white, // White text in dark mode
                backgroundColor: theme.colorScheme.primary, // Primary color background
              ),
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  // Function to update note in firestore
  Future<void> _updateNote() async {
    final title = _titleController.text;
    final content = _contentController.text;

    if (title.isNotEmpty && content.isNotEmpty) {
      try {
        // Update note in firestore using provided note ID
        await FirebaseFirestore.instance
            .collection('notes')
            .doc(widget.noteId)
            .update({
          'title': title,
          'content': content,
          'updatedAt': Timestamp.now(),
        });
        Navigator.pop(context); // Return to previous screen after updating
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating note: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
    }
  }
}
