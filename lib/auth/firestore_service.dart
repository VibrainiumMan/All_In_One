import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> createFlashCard(String setName) async {
    if (user != null) {
      DocumentReference setRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .collection('FlashCardSets')
          .doc(setName);

      await setRef.set({
        'setName': setName,
        'createdAt': Timestamp.now(),
      });
    }
  }

  Future<void> addFlashCardToSet(
      String setName, String frontText, String backText) async {
    if (user != null) {
      DocumentReference cardRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .collection('FlashCardSets')
          .doc(setName)
          .collection('FlashCards')
          .doc();

      await cardRef.set({
        'frontText': frontText,
        'backText': backText,
        'createdAt': Timestamp.now(),
      });
    }
  }

  Future<void> deleteFlashCard(String setName, String cardId) async {
    if (user != null) {
      DocumentReference cardRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .collection('FlashCardSets')
          .doc(setName)
          .collection('FlashCards')
          .doc(cardId);

      await cardRef.delete();
    }
  }

  Stream<QuerySnapshot> getFlashCards(String setName) {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(user!.email)
        .collection('FlashCardSets')
        .doc(setName)
        .collection('FlashCards')
        .snapshots();
  }

  Future<void> createFlashcardDeck(String deckName) async {
    if (user != null) {
      CollectionReference decks = FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .collection('FlashcardDecks');

      await decks.add({
        'deckName': deckName,
      });
    }
  }

  Future<void> deleteFlashcardDeck(String deckId) async {
    if (user != null) {
      DocumentReference deckRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .collection('FlashcardDecks')
          .doc(deckId);

      await deckRef.delete();
    }
  }

  Stream<QuerySnapshot> getDecks() {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(user!.email)
        .collection('FlashcardDecks')
        .snapshots();
  }
}
