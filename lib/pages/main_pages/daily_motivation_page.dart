import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class DailyMotivationPage extends StatefulWidget {
  const DailyMotivationPage({super.key});

  @override
  State<DailyMotivationPage> createState() => _DailyMotivationPageState();
}

class _DailyMotivationPageState extends State<DailyMotivationPage> {
  String dailyMotivation = 'Fetching your motivational quote...';
  final String apiUrl = "https://zenquotes.io/api/quotes/your_key"; // Replace with your actual API key

  @override
  void initState() {
    super.initState();
    _checkUserAuthentication();
  }

  // Check if the user is logged in
  Future<void> _checkUserAuthentication() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _fetchDailyMotivation();  // Fetch the quote if the user is logged in
    } else {
      setState(() {
        dailyMotivation = 'Please log in to view your daily motivation.';
      });
    }
  }

  Future<void> _fetchDailyMotivation() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        setState(() {
          dailyMotivation = data[0]['q']; // Assuming the quote is in the 'q' field
        });

        // Show the motivational quote in a dialog when the app starts
        _showMotivationDialog();
      } else {
        setState(() {
          dailyMotivation = 'Failed to load motivation. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        dailyMotivation = 'Error fetching motivation. Please check your connection.';
      });
    }
  }

  void _showMotivationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Daily Motivation'),
          content: Text(dailyMotivation),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Motivation'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Welcome! Your motivational quote will appear shortly.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
