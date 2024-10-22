import 'package:flutter/material.dart';

import '../../components/my_elevated_button.dart';

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
        backgroundColor: const Color(0xFF8CAEB7),
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
                style: TextStyle(fontSize: 35, color: Theme.of(context).colorScheme.inversePrimary),
              ),
              const SizedBox(height: 60),
              MyElevatedButton(
                text: "Back to Home",
                onPressed: () {
                  Navigator.popUntil(
                    context,
                        (route) => route.isFirst,
                  ); // Go back to the previous screen
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
