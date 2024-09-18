import 'package:all_in_one/components/my_button.dart';
import 'package:all_in_one/pages/auth_pages/flash_card_manager_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
            // Add Schedule Section
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.inversePrimary),
              ),
              margin: const EdgeInsets.all(10),
              width: 400,
              height: 200,
              child: const Center(
                child: Text("Add Schedule"),
              ),
            ),
            // Add Calendar Section
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.inversePrimary),
              ),
              margin: const EdgeInsets.all(10),
              width: 400,
              height: 200,
              child: const Center(
                child: Text("Add Calendar"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: MyButton(
                text: "Flash Card",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlashCardManagerPage(),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
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
