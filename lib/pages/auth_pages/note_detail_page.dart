import 'package:flutter/material.dart';

class NoteDetailPage extends StatelessWidget {
  final Map<String, dynamic> note;

  const NoteDetailPage({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var createdAt = note['createdAt'] != null
        ? note['createdAt'].toDate()
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(note['title'] ?? 'No Title'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note['title'] ?? 'No Title',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              note['content'] ?? 'No Content',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              createdAt != null
                  ? "Created on: ${createdAt.day}/${createdAt.month}/${createdAt.year}"
                  : "Created on: Unknown Date",
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
