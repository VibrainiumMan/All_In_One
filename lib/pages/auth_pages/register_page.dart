import 'package:flutter/material.dart';

import '../../components/my_button.dart';
import '../../components/text_field.dart';


class RegisterPage extends StatefulWidget {
  final void Function()? onTap;


  RegisterPage({super.key, required this.onTap});


  @override
  State<RegisterPage> createState() => _RegisterPageState();
}


class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPWController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 80,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),


              const SizedBox(height: 40),


              MyTextField(
                hintText: "Username",
                obscureText: false,
                controller: usernameController,
              ),


              const SizedBox(height: 15),


              //Email field
              MyTextField(
                hintText: "Email",
                obscureText: false,
                controller: emailController,
              ),


              const SizedBox(height: 15),


              //Password field
              MyTextField(
                hintText: "Password",
                obscureText: true,
                controller: passwordController,
              ),


              const SizedBox(height: 15),


              //Confirm Password
              MyTextField(
                hintText: "Confirm Password",
                obscureText: true,
                controller: confirmPWController,
              ),


              const SizedBox(height: 25),


              MyButton(
                text: "Register",
                onTap: (){},
              ),


              const SizedBox(height: 15),


              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: const Text(
                      "Login Here ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
