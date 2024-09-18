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
  final String apiUrl = "https://zenquotes.io/api/quotes/your_key";

  @override
  void initState() {
    super.initState();
    _checkUserAuthentication();
  }


  Future<void> _checkUserAuthentication() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _fetchDailyMotivation();
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
          dailyMotivation = data[0]['q'];
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline),
            SizedBox(width: 8),
            Text('Daily Motivation'),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Quote of the day',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    dailyMotivation,
                    style: TextStyle(
                      fontSize: 24,
                      fontStyle: FontStyle.italic,
                      color: Colors.blueGrey.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: _fetchDailyMotivation,
                icon: const Icon(Icons.refresh),
                label: const Text('Click to get a new quote'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCA7E8D), // Background color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
