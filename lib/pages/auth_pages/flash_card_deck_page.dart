import 'package:all_in_one/components/my_button.dart';
import 'package:all_in_one/components/text_field.dart';
import 'package:all_in_one/pages/auth_pages/flash_card_quiz_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../auth/firestore_service.dart';
import '../../components/flash_card.dart';
import '../../components/my_floating_action_button.dart';

class FlashcardDeckPage extends StatefulWidget {
  final String deckId;
  final String deckName;

  const FlashcardDeckPage({required this.deckId, required this.deckName});

  @override
  _FlashcardDeckPageState createState() => _FlashcardDeckPageState();
}

class _FlashcardDeckPageState extends State<FlashcardDeckPage> {
  final FirestoreService flashCardManager = FirestoreService();

  Future<void> showAddFlashCardDialog(BuildContext context) async {
    final TextEditingController frontTextController = TextEditingController();
    final TextEditingController backTextController = TextEditingController();
    final TextEditingController examDateController =
        TextEditingController(); // 控制器用于输入日期

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.background,
          title: Text(
            'Add FlashCard',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyTextField(
                hintText: "Question",
                obscureText: false,
                controller: frontTextController,
              ),
              const SizedBox(height: 10.0),
              MyTextField(
                controller: backTextController,
                obscureText: false,
                hintText: "Answer",
              ),
              const SizedBox(height: 10.0),
              MyTextField(
                controller: examDateController,
                obscureText: false,
                hintText: "Exam Date (YYYY-MM-DD)",
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 5.0),
            TextButton(
              child: Text(
                "Save",
                style: TextStyle(
                  color: Colors.green,
                ),
              ),
              onPressed: () {
                if (frontTextController.text.isNotEmpty &&
                    backTextController.text.isNotEmpty &&
                    examDateController.text.isNotEmpty) {
                  DateTime? examDate =
                      DateTime.tryParse(examDateController.text);
                  if (examDate != null) {
                    flashCardManager.addFlashCardToSet(
                      widget.deckName,
                      frontTextController.text,
                      backTextController.text,
                      examDate,
                      initialPriority: 5,
                    );
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8CAEB7),
        title: Text(
          '${widget.deckName} Deck',
          style: TextStyle(
            fontSize: 25,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.quiz,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FlashCardQuizPage(deckName: widget.deckName),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: flashCardManager.getFlashCards(widget.deckName),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final flashCards = snapshot.data!.docs.map((doc) {
            return Padding(
              padding: const EdgeInsets.all(15.0),
              child: FlashCard(
                frontText: doc['frontText'],
                backText: doc['backText'],
                onDelete: () {
                  flashCardManager.deleteFlashCard(widget.deckName, doc.id);
                },
                priority: doc['priority'],
                deckName: widget.deckName,
                cardId: doc.id,
                examDate: (doc['examDate'] as Timestamp).toDate(),
              ),
            );
          }).toList();
          const SizedBox(height: 5,);

          return ListView.builder(
            itemCount: flashCards.length,
            itemBuilder: (context, index) {
              return flashCards[index];
            },
          );
        },
      ),
      floatingActionButton: MyFloatingActionButton(
        onPressed: () {
          showAddFlashCardDialog(context);
        },
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
    );
  }
}
