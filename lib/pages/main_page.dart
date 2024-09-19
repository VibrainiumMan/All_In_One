import 'package:all_in_one/pages/main_pages/daily_motivation_page.dart';
import 'package:all_in_one/pages/main_pages/home_page.dart';
import 'package:all_in_one/pages/main_pages/message_pages/MessagesPage.dart';
import 'package:all_in_one/pages/main_pages/posting_page.dart';
import 'package:all_in_one/pages/main_pages/profile_page.dart';
import 'package:all_in_one/pages/main_pages/task_page.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int pageIndex = 2;
  final List<Widget> pages = [
    const MessagesPage(),
    const PostingPage(),
    const HomePage(),
    const TaskPage(),
    const ProfilePage(),
    const DailyMotivationPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[pageIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: pageIndex,
        onTap: (index) {
          setState(() {
            pageIndex = index;
          });
        },
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        selectedItemColor: Theme.of(context).colorScheme.inversePrimary,
        unselectedItemColor: Theme.of(context).colorScheme.primary,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
          BottomNavigationBarItem( // Add the new item for Daily Motivation
            icon: Icon(Icons.format_quote),
            label: '',
          ),
        ],
      ),
    );
  }
}
