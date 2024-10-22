import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zefyrka/zefyrka.dart';
import 'dart:convert';

import '../../components/text_field.dart';

class EditNotePage extends StatefulWidget {
  final String noteId;
  final Map<String, dynamic> note;

  const EditNotePage(this.noteId, this.note, {Key? key}) : super(key: key);

  @override
  _EditNotePageState createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late TextEditingController _titleController;
  late ZefyrController _contentController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note['title']);
    _initializeContent();
  }

  void _initializeContent() {
    try {
      final contentJson = jsonDecode(widget.note['content']);
      final document = NotusDocument.fromJson(contentJson);
      _contentController = ZefyrController(document);
    } catch (e) {
      print('Error parsing note content: $e');
      _contentController = ZefyrController(NotusDocument());
    }
  }

  Future<void> _updateNote() async {
    final title = _titleController.text;
    final content = jsonEncode(_contentController.document.toDelta().toJson());

    if (title.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('notes')
            .doc(widget.noteId)
            .update({
          'title': title,
          'content': content,
          'updatedAt': Timestamp.now(),
        });
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating note: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title for the note")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8CAEB7),
        title: Text(
          "Edit Note",
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontSize: 25,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.save,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            onPressed: _updateNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MyTextField(
              controller: _titleController,
              hintText: "Title",
              obscureText: false,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ZefyrEditor(
                controller: _contentController,
                focusNode: _focusNode,
                autofocus: false,
                readOnly: false,
                padding: const EdgeInsets.all(16),
              ),
            ),
            ZefyrToolbar.basic(controller: _contentController),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
