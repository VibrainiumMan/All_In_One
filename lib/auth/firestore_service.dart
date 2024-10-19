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
      String setName, String frontText, String backText, {int initialPriority = 5}) async {
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
        'priority' : initialPriority,   // Set init priority
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
        .orderBy('priority', descending: true)
        .snapshots();
  }

  Future<void> updateFlashCardPriority(String setName, String cardId, int newPriority) async {
    if (user != null) {
      DocumentReference cardRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .collection('FlashCardSets')
          .doc(setName)
          .collection('FlashCards')
          .doc(cardId);

      await cardRef.update({
        'priority': newPriority,
      });
    }
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

  // Future<List<Map<String, dynamic>>> getRandomFlashCards(String setName, int count) async {
  //   if (user != null) {
  //     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  //         .collection('Users')
  //         .doc(user!.email)
  //         .collection('FlashCardSets')
  //         .doc(setName)
  //         .collection('FlashCards')
  //         .get();
  //
  //     final allFlashcards = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  //
  //     // Shuffle and return 10 flashcards, or less if there aren't 10 available
  //     allFlashcards.shuffle();
  //     return allFlashcards.take(count).toList();
  //   }
  //   return [];
  // }

  Future<List<Map<String, dynamic>>> getRandomFlashCards(String setName, int count) async {
    if (user != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .collection('FlashCardSets')
          .doc(setName)
          .collection('FlashCards')
          .get();

      final allFlashcards = querySnapshot.docs.map((doc) {
        return {
          'cardId': doc.id,
          'setName': setName,
          ...doc.data() as Map<String, dynamic>
        };
      }).toList();

      // Shuffle and return flashcards
      allFlashcards.shuffle();
      return allFlashcards.take(count).toList();
    }
    return [];
  }
}