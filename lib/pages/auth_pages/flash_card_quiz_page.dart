
import 'package:all_in_one/pages/auth_pages/quiz_result_page.dart';
import 'package:flutter/material.dart';
import '../../auth/firestore_service.dart';
import '../../components/text_field.dart';

class FlashCardQuizPage extends StatefulWidget {
  final String deckName;

  const FlashCardQuizPage({required this.deckName});

  @override
  _FlashCardQuizPageState createState() => _FlashCardQuizPageState();
}

class _FlashCardQuizPageState extends State<FlashCardQuizPage> {
  final FirestoreService flashCardManager = FirestoreService();
  List<Map<String, dynamic>> flashCards = [];
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  final TextEditingController answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    generateQuiz();
  }

  Future<void> generateQuiz() async {
    List<Map<String, dynamic>> cards =
    await flashCardManager.getRandomFlashCards(widget.deckName, 10);
    setState(() {
      flashCards = cards;
    });
  }

  void checkAnswer() {
    final currentFlashCard = flashCards[currentQuestionIndex];
    final setName = currentFlashCard['setName'];
    final cardId = currentFlashCard['cardId'];
    final answerText = answerController.text;
    final backText = currentFlashCard['backText'];
    int currentPriority = currentFlashCard['priority'];

    print('Set Name: $setName');
    print('Card ID: $cardId');
    print('Current Priority: ${currentFlashCard['priority']}, Type: ${currentFlashCard['priority'].runtimeType}');
    print('Current flashcard: $currentFlashCard');
    print('Answer text: $answerText');
    print('Back text: $backText');

    if (answerText.trim().toLowerCase() == backText.trim().toLowerCase()) {
      correctAnswers++;

      // Set priority -1 when answer correct
      if (currentPriority > 1) {
        currentPriority--;
      }
    } else {
      // Set priority +1 when answer wrong
      if (currentPriority < 10) {
        currentPriority++;
      }
    }

    // Update database
    flashCardManager.updateFlashCardPriority(
      setName,
      cardId,
      currentPriority,
    );

    answerController.clear();
  }

  void showResults(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultPage(
          correctAnswers: correctAnswers,
          totalQuestions: flashCards.length,
          deckName: widget.deckName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (flashCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz - ${widget.deckName}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentFlashCard = flashCards[currentQuestionIndex];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('Quiz - ${widget.deckName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Question ${currentQuestionIndex + 1}/${flashCards.length}',
              style: const TextStyle(fontSize: 50),
            ),
            const SizedBox(height: 30),
            Text(
              currentFlashCard['frontText'],
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 20),
            MyTextField(
              controller: answerController,
              obscureText: false,
              hintText: "Enter Answer",
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                checkAnswer();
                if (currentQuestionIndex < flashCards.length - 1) {
                  setState(() {
                    currentQuestionIndex++;
                  });
                } else {
                  showResults(context);
                }
              },
              child: Text(currentQuestionIndex < flashCards.length - 1
                  ? 'Next Question'
                  : 'Finish Quiz',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}