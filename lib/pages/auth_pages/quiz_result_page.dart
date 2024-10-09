import 'package:all_in_one/pages/auth_pages/flash_card_deck_page.dart';
import 'package:flutter/material.dart';

class QuizResultPage extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;
  final String deckName;

  const QuizResultPage(
      {required this.correctAnswers,
        required this.totalQuestions,
        required this.deckName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Quiz Result'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'You got $correctAnswers out of $totalQuestions correct!',
                style: const TextStyle(fontSize: 35),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                        (route) => route.isFirst,
                  ); // Go back to the previous screen
                },
                child: const Text(
                  'Back to Deck',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
