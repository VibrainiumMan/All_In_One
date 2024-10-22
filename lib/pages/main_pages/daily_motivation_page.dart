import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyMotivationPage extends StatefulWidget {
  const DailyMotivationPage({super.key});

  @override
  State<DailyMotivationPage> createState() => _DailyMotivationWidgetState();
}

class _DailyMotivationWidgetState extends State<DailyMotivationPage> {
  String dailyMotivation = 'Fetching your motivational quote...';
  final String apiUrl = "https://zenquotes.io/api/quotes/your_key";



  @override
  void initState() {
    super.initState();
    _loadSavedQuote();
    _checkUserAuthentication();
  }

  Future<void> _loadSavedQuote() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedQuote = prefs.getString('dailyMotivation');

    if (savedQuote != null && savedQuote.isNotEmpty) {
      setState(() {
        dailyMotivation = savedQuote;
      });
    } else {
      _fetchDailyMotivation();
    }
  }


  Future<void> _checkUserAuthentication() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && dailyMotivation == 'Fetching your motivational quote...') {
      _fetchDailyMotivation();
    } else if(user == null){
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
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('dailyMotivation', dailyMotivation);
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Quote of the day',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Card(
          color: Theme.of(context).colorScheme.secondary,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              dailyMotivation,
              style: TextStyle(
                fontSize: 24,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 60),
        GestureDetector(
          onTap: _fetchDailyMotivation,
          child: const Icon(
            Icons.refresh,
            size: 40,
            color: const Color(0xFF8CAEB7),
          ),
        ),
      ],
    );
  }
}