import 'package:all_in_one/components/my_floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/firestore_service.dart';
import '../../components/my_button.dart';
import '../../components/text_field.dart';
import 'flash_card_deck_page.dart';

class FlashCardManagerPage extends StatefulWidget {
  const FlashCardManagerPage({super.key});

  @override
  _FlashCardManagerPageState createState() => _FlashCardManagerPageState();
}

class _FlashCardManagerPageState extends State<FlashCardManagerPage> {
  final FirestoreService deckManager = FirestoreService();

  Future<void> showCreateDeckDialog(BuildContext context) async {
    final TextEditingController deckNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          title: const Text('Create Flashcard Deck'),
          content: MyTextField(
            controller: deckNameController,
            hintText: "Deck Name",
            obscureText: false,
          ),
          actions: [
            MyButton(
              onTap: () {
                Navigator.of(context).pop();
              },
              text: "Cancel",
            ),
            const SizedBox(height: 5.0,),
            MyButton(
              onTap: () {
                if (deckNameController.text.isNotEmpty) {
                  deckManager.createFlashcardDeck(deckNameController.text);
                  Navigator.of(context).pop();
                }
              },
              text: "Text",
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
        title: const Text('FlashCard Manager'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: deckManager.getDecks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final decks = snapshot.data!.docs.map((doc) {
            return ListTile(
              title: Text(doc['deckName']),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  deckManager.deleteFlashcardDeck(doc.id);
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlashcardDeckPage(
                        deckId: doc.id, deckName: doc['deckName']),
                  ),
                );
              },
            );
          }).toList();

          return ListView(
            children: decks,
          );
        },
      ),
      floatingActionButton: MyFloatingActionButton(
        onPressed: () {
          showCreateDeckDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
