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
              text: "Save",
            ),
          ],
        );
      },
    );
  }

  Future<void> showDeleteConfirmationDialog(
      BuildContext context, String deckId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Flashcard Deck'),
          content: const Text('Are you sure you want to delete this deck?'),
          actions: <Widget>[
            MyButton(
              onTap: () {
                Navigator.of(context).pop(); // Cancel deletion
              },
              text: 'Cancel',
            ),
            MyButton(
              onTap: () {
                deckManager.deleteFlashcardDeck(deckId);
                Navigator.of(context).pop(); // Confirm deletion
              },
              text: 'Delete',
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
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    showDeleteConfirmationDialog(context, doc.id);
                  }
                  // You can add more actions if needed
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                  // Add other actions here if needed
                ],
                icon: const Icon(Icons.more_vert),
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