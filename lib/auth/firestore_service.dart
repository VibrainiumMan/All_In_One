import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<String?> getUsername() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users') // Use the same collection name
          .doc(user!.uid) // Using uid instead of email
          .get();

      // Cast the data to a Map<String, dynamic> before accessing it
      final data = userDoc.data() as Map<String, dynamic>?;

      // Assuming the username is stored under a field called 'name'
      return data?['name'] as String?;
    }
    return null;
  }

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
      String setName, String frontText, String backText,DateTime examDate, {int initialPriority = 5}) async {
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
        'examDate': Timestamp.fromDate(examDate),
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
        .orderBy('examDate')
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
      DateTime now = DateTime.now();
      DateTime sevenDaysFromNow = now.add(Duration(days: 7));

      QuerySnapshot withinSevenDaysSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .collection('FlashCardSets')
          .doc(setName)
          .collection('FlashCards')
          .where('examDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('examDate', isLessThanOrEqualTo: Timestamp.fromDate(sevenDaysFromNow))
          .orderBy('examDate')
          .get();

      QuerySnapshot afterSevenDaysSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.email)
          .collection('FlashCardSets')
          .doc(setName)
          .collection('FlashCards')
          .where('examDate', isGreaterThan: Timestamp.fromDate(sevenDaysFromNow))
          .where('priority', isGreaterThan: 1)
          .orderBy('examDate')
          .get();

      List<Map<String, dynamic>> allFlashcards = [];

      allFlashcards.addAll(withinSevenDaysSnapshot.docs.map((doc) {
        return {
          'cardId': doc.id,
          'setName': setName,
          ...doc.data() as Map<String, dynamic>
        };
      }).toList());

      allFlashcards.addAll(afterSevenDaysSnapshot.docs.map((doc) {
        return {
          'cardId': doc.id,
          'setName': setName,
          ...doc.data() as Map<String, dynamic>
        };
      }).toList());

      allFlashcards.shuffle();
      return allFlashcards.take(count).toList();
    }
    return [];
  }

}