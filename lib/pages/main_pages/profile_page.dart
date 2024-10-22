import 'package:all_in_one/pages/main_pages/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../auth/firestore_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    String? username = await FirestoreService().getUsername();
    setState(() {
      _username = username;
    });
  }

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8CAEB7),
        title: Text(
          "Profile",
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontSize: 25,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 80,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            const SizedBox(height: 5),
            // Display the username or a loading indicator
            Text(
              _username != null ? _username! : "Loading...",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),

            //Settings button
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: ListTile(
                leading: Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                title: Text(
                  "Settings",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                  debugPrint("Tapped: settings");
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(30),
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                title: Text(
                  "Logout",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: logout,
              ),
            )
          ],
        ),
      ),
    );
  }
}
