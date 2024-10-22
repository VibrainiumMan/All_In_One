import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zefyrka/zefyrka.dart';
import 'dart:convert';

import '../../components/text_field.dart';

class AddNotePage extends StatefulWidget {
  const AddNotePage({Key? key}) : super(key: key);

  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late ZefyrController _controller;

  @override
  void initState() {
    super.initState();
    final document = NotusDocument();
    _controller = ZefyrController(document);
  }

  String _convertDocumentToJson() {
    final delta = _controller.document.toDelta();
    return jsonEncode(delta.toJson());
  }

  Future<void> _saveNote() async {
    final title = _titleController.text;
    final user = FirebaseAuth.instance.currentUser;

    if (title.isEmpty) {
      _showErrorSnackBar("Please enter a title for the note.");
      return;
    }

    if (user == null) {
      _showErrorSnackBar(
          "User not authenticated. Please log in and try again.");
      return;
    }

    try {
      final contentJson = _convertDocumentToJson();

      await FirebaseFirestore.instance.collection('notes').add({
        'title': title,
        'content': contentJson,
        'owner': user.email,
        'createdAt': Timestamp.now(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note saved successfully")),
      );
    } catch (e) {
      _showErrorSnackBar("Error saving note: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8CAEB7),
        title: Text(
          "Add Note",
          style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontSize: 25),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Theme.of(context).colorScheme.inversePrimary,),
            onPressed: _saveNote,
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
                controller: _controller,
                focusNode: _focusNode,
                padding: const EdgeInsets.all(8.0),
              ),
            ),
            const SizedBox(height: 20),
            ZefyrToolbar.basic(controller: _controller),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
