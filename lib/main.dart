import 'package:all_in_one/firebase_options.dart';
import 'package:all_in_one/pages/auth_pages/login_or_register.dart';
import 'package:all_in_one/themes/dark_mode.dart';
import 'package:all_in_one/themes/light_mode.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await dotenv.load(fileName: ".env");
  //await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //String apiKey = dotenv.env['API_KEY'] ?? '';
 await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: 'AIzaSyCyJBbJRfbSRuM-vv-yA8KbZpqV1SMjiAQ',
        appId: '1:611940341499:android:503d93099856136b79025e',
        messagingSenderId: '611940341499',
        projectId: 'all-in-one-7f601',
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "All In One",
      theme: lightMode,
      darkTheme: darkMode,
      home: const LoginOrRegister(),
    );
  }
}
