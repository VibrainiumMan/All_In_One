import 'package:all_in_one/pages/auth_pages/flash_card_manager_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:all_in_one/pages/auth_pages/add_note_page.dart';
import 'package:all_in_one/pages/auth_pages/view_notes_page.dart';
import 'package:all_in_one/pages/auth_pages/timer_screen.dart';
import 'package:all_in_one/pages/main_pages/daily_motivation_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double dailyProgress = 0.0;
  double weeklyProgress = 0.0;
  double monthlyProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateProgress();
  }

  void _calculateProgress() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userEmail = user.email;

      var tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('owner', isEqualTo: userEmail)
          .get();

      int dailyTotal = 0, dailyCompleted = 0;
      int weeklyTotal = 0, weeklyCompleted = 0;
      int monthlyTotal = 0, monthlyCompleted = 0;

      for (var doc in tasksSnapshot.docs) {
        var data = doc.data();
        String type = data['type'];
        bool isCompleted = data['isCompleted'] ?? false;

        if (type == 'Daily') {
          dailyTotal++;
          if (isCompleted) dailyCompleted++;
        } else if (type == 'Weekly') {
          weeklyTotal++;
          if (isCompleted) weeklyCompleted++;
        } else if (type == 'Monthly') {
          monthlyTotal++;
          if (isCompleted) monthlyCompleted++;
        }
      }

      setState(() {
        dailyProgress = dailyTotal > 0 ? dailyCompleted / dailyTotal : 0;
        weeklyProgress = weeklyTotal > 0 ? weeklyCompleted / weeklyTotal : 0;
        monthlyProgress =
        monthlyTotal > 0 ? monthlyCompleted / monthlyTotal : 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          "Home Page",
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: ListView(
          children: [
            // Add Note and View Notes buttons at the top
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //Flash Cards manager button
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const FlashCardManagerPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.view_agenda, size: 40,),
                      ),
                      const Text("Flash Cards")
                    ],
                  ),
                  const SizedBox(width: 50.0),
                  //Add Note Button
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, size: 40),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddNotePage(),
                            ),
                          );
                        },
                      ),
                      const Text("Add Note"),
                    ],
                  ),
                  const SizedBox(width: 50.0),
                  //View Notes button
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.book, size: 40),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ViewNotesPage(),
                            ),
                          );
                        },
                      ),
                      const Text("View My Notes"),
                    ],
                  ),
                ],
              ),
            ),
            // ToDo List Progress Section
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.inversePrimary),
              ),
              margin: const EdgeInsets.all(10),
              width: 400,
              height: 150,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildProgressIndicator("Daily", dailyProgress),
                    _buildProgressIndicator("Weekly", weeklyProgress),
                    _buildProgressIndicator("Monthly", monthlyProgress),
                  ],
                ),
              ),
            ),
            // daily motivation quote
            const SizedBox(height: 40),
            const DailyMotivationPage(),
            const SizedBox(height: 60),

            // Timer button at the bottom
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.alarm, // Alarm icon
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black // Black in light mode
                      : Colors.white, // White in dark mode
                ),
                label: Text(
                  "Study Timer",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black // Use black in light mode
                        : Colors.white, // Use white in dark mode
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TimerScreen(showNotification: _showNotification),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[300] // Slightly darker button background in light mode
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show notification
  void _showNotification(String title, String body) {
    // Implement notification logic
  }

  Widget _buildProgressIndicator(String type, double progress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 7,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary),
              ),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(type),
      ],
    );
  }
}
