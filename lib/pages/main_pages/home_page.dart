import 'package:all_in_one/pages/auth_pages/flash_card_manager_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:all_in_one/pages/auth_pages/add_note_page.dart';
import 'package:all_in_one/pages/auth_pages/view_notes_page.dart';
import 'package:all_in_one/pages/auth_pages/timer_screen.dart';
import 'package:all_in_one/pages/main_pages/daily_motivation_page.dart';
import 'package:all_in_one/pages/main_pages/rewards_page.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double dailyProgress = 0.0;
  double weeklyProgress = 0.0;
  double monthlyProgress = 0.0;

  int totalPoints = 10; // Total points the user needs to redeem a reward
  int currentPoints = 0; // User's current points

  @override
  void initState() {
    super.initState();
    _calculateProgress();

  }

  void _calculateProgress() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Fetch the user's document from Firestore
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data();
        setState(() {
          currentPoints = data?['points'] ?? 0; // Load points from Firestore
        });
      }

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
        monthlyProgress = monthlyTotal > 0 ? monthlyCompleted / monthlyTotal : 0;
      });
    }
  }

  // Function to update points after study session
  void _updatePoints(int pointsEarned) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        currentPoints += pointsEarned; // Add earned points to current points

        // Check if the user has earned enough points for a reward
        if (currentPoints >= totalPoints) {
          _showRewardDialog();
          currentPoints = 0; // Reset points after earning a reward
        }
      });

      // Save the updated points in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // Use user's unique ID
          .set({
        'points': currentPoints,
      }, SetOptions(merge: true)); // Merge to update the existing points field
    }
  }


  // Show reward dialog when the user earns enough points
  void _showRewardDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Congratulations!"),
          content: Text("You've earned a free coffee voucher!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // Calculate the progress for the points progress bar
    double pointsProgress = currentPoints / totalPoints;
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
            // Points Progress Bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    "You need ${totalPoints - currentPoints} more points to redeem a reward!",
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: pointsProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ],
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
                      builder: (context) => TimerScreen(
                            showNotification: _showNotification,
                            updatePoints: _updatePoints, // Pass the points updating function
                          ),
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
          // Add the View Rewards button here
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RewardsPage(currentPoints: currentPoints), // Pass current points
                  ),
                );
              },
              child: const Text('View Rewards'),
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
