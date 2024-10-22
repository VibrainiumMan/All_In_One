import 'package:flutter/material.dart';
import 'package:zefyrka/zefyrka.dart';
import 'dart:convert';

class NoteDetailPage extends StatelessWidget {
  final Map<String, dynamic> note;

  const NoteDetailPage({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var createdAt =
        note['createdAt'] != null ? note['createdAt'].toDate() : null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8CAEB7),
        title: Text(
          note['title'] ?? 'No Title',
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontSize: 25,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note['title'] ?? 'No Title',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildNoteContent(note['content']),
            ),
            const SizedBox(height: 20),
            Text(
              createdAt != null
                  ? "Created on: ${createdAt.day}/${createdAt.month}/${createdAt.year}"
                  : "Created on: Unknown Date",
              style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteContent(String? content) {
    if (content == null || content.isEmpty) {
      return const Text('No content', style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),);
    }

    try {
      final jsonContent = jsonDecode(content);
      final document = NotusDocument.fromJson(jsonContent);

      return ZefyrEditor(
        controller: ZefyrController(document),
        readOnly: true,
        showCursor: false,
      );
    } catch (e) {
      print('Error parsing note content: $e');
      return Text(content); // Fallback to displaying raw content
    }
  }
}
