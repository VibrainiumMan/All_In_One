import 'package:all_in_one/pages/auth_pages/flash_card_manager_page.dart';
import 'package:all_in_one/pages/main_pages/progress_indicator_widget.dart';
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
    _listenToTaskUpdates();
    _loadCurrentPoints();
  }

  // Function to load the current points from Firestore
  void _loadCurrentPoints() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userId = user.uid;

      // Fetch the user's current points from Firestore
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // If the document exists, get the points; otherwise, default to 0
      setState(() {
        currentPoints = userDoc.data()?['points'] ?? 0;
      });
    }
  }

  void _listenToTaskUpdates() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userEmail = user.email;

      FirebaseFirestore.instance
          .collection('tasks')
          .where('owner', isEqualTo: userEmail)
          .snapshots()
          .listen((tasksSnapshot) {
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
      });
    }
  }

  void _updatePoints(int pointsEarned) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        currentPoints += pointsEarned; // Add earned points to current points

        // Checks if the user has earned enough points for a coffee voucher
        if (currentPoints >= 10) {
          _showRewardDialog('Free Coffee');
          _addVoucher('Free Coffee', 10); // Add coffee voucher and deduct 10 points
          currentPoints = 0; // Reset points after giving the voucher
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




// Function to add a voucher and subtract the appropriate points
  void _addVoucher(String reward, int cost) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vouchers')
          .add({
        'voucher': reward,  // Voucher title (always Free Coffee)
        'isRedeemed': false,  // Indicates that the voucher has not been redeemed yet
      });
    }
  }


  // Show reward dialog when the user earns enough points
  void _showRewardDialog(String rewardTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Congratulations!"),
          content: Text("You've earned a $rewardTitle voucher!"),
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
                    ProgressIndicatorWidget(type: "Daily", progress: dailyProgress),
                    ProgressIndicatorWidget(type: "Weekly", progress: weeklyProgress),
                    ProgressIndicatorWidget(type: "Monthly", progress: monthlyProgress),
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
                    currentPoints >= totalPoints
                        ? "You have enough points for a reward!"
                        : "You need ${totalPoints - currentPoints} more points to redeem a reward!",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: currentPoints >= totalPoints
                        ? 1.0
                        : currentPoints / totalPoints, // Adjust to prevent exceeding progress
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey, // Set the background color
                foregroundColor: Colors.white, // Set the text color
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Adjust padding
                textStyle: const TextStyle(fontSize: 18), // Set text size
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RewardsPage(),
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

}
