import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../components/my_button.dart';
import '../../components/text_field.dart';
import '../../helper/helper_methods.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Function to reset password
  void resetPassword() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      displayMessageToUser("Passwords don't match", context);
      return;
    }

    try {
      String email = emailController.text.trim();
      if (email.isEmpty) {
        displayMessageToUser("Please enter your email", context);
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // You can show a success message and navigate back to the login page.
      displayMessageToUser("Password reset email sent", context);
    } on FirebaseAuthException catch (e) {
      displayMessageToUser(e.message.toString(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8CAEB7),
        title: Text('Reset Password', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary, fontSize: 25),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/images/All-In-One-Logo.png'),

            // Email field
            MyTextField(
              hintText: 'Enter your email',
              obscureText: false,
              controller: emailController,
            ),
            const SizedBox(height: 20),

            // New password field
            MyTextField(
              hintText: 'New password',
              obscureText: true,
              controller: newPasswordController,
            ),
            const SizedBox(height: 20),

            // Confirm password field
            MyTextField(
              hintText: 'Confirm new password',
              obscureText: true,
              controller: confirmPasswordController,
            ),
            const SizedBox(height: 25),

            // Confirm button
            MyButton(
              text: 'Reset Password',
              onTap: resetPassword,
            ),
          ],
        ),
      ),
    );
  }
}
