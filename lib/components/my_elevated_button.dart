import 'package:flutter/material.dart';

class MyElevatedButton extends StatelessWidget {
  final void Function()? onPressed;
  final String text;

  const MyElevatedButton(
      {super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors
            .grey[300] // Slightly darker button background in light mode
            : Theme.of(context).colorScheme.primary,
      ),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary, fontSize: 20),
      ),
    );
  }
}
