import 'package:all_in_one/pages/main_pages/home_page.dart';
import 'package:all_in_one/pages/main_pages/message_pages/friends_page.dart';
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
  int pageIndex = 2; // Starting from HomePage (index 2)
  final PageController _pageController = PageController(initialPage: 2); // Initialize PageController

  final List<Widget> pages = [
    const FriendsPage(),
    const PostingPage(),
    const HomePage(),
    const TaskPage(),
    const ProfilePage(),
  ];

  @override
  void dispose() {
    _pageController.dispose(); // Dispose of the PageController when not needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            pageIndex = index;
          });
        },
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: pageIndex,
        onTap: (index) {
          setState(() {
            pageIndex = index;
            _pageController.jumpToPage(index); // Change page on bottom nav tap
          });
        },
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        selectedItemColor: Theme.of(context).colorScheme.inversePrimary,
        unselectedItemColor: const Color(0xFF8CAEB7),
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
        ],
      ),
    );
  }
}