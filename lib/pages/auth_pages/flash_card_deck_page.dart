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

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          title: const Text('Add FlashCard'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyTextField(
                hintText: "Question",
                obscureText: false,
                controller: frontTextController,
              ),
              const SizedBox(height: 5.0),
              MyTextField(
                controller: backTextController,
                obscureText: false,
                hintText: "Answer",
              ),
            ],
          ),
          actions: [
            MyButton(
              onTap: () {
                Navigator.of(context).pop();
              },
              text: "Cancel",
            ),
            const SizedBox(height: 5.0),
            MyButton(
              onTap: () {
                if (frontTextController.text.isNotEmpty &&
                    backTextController.text.isNotEmpty) {
                  flashCardManager.addFlashCardToSet(widget.deckName,
                      frontTextController.text, backTextController.text);
                  Navigator.of(context).pop();
                }
              },
              text: "Add",
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
        title: Text('${widget.deckName} Deck'),
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz),
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
            return FlashCard(
              frontText: doc['frontText'],
              backText: doc['backText'],
              onDelete: () {
                flashCardManager.deleteFlashCard(widget.deckName, doc.id);
              },
            );
          }).toList();

          return ListView(
            children: flashCards,
          );
        },
      ),
      floatingActionButton: MyFloatingActionButton(
        onPressed: () {
          showAddFlashCardDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
