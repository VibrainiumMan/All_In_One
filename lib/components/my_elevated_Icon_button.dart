import 'package:flutter/material.dart';

class MyElevatedIconButton extends StatelessWidget {
  final void Function()? onPressed;
  final Icon icon;
  final String label;

  const MyElevatedIconButton(
      {super.key,
        required this.onPressed,
        required this.icon,
        required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(
        label,
        style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary, fontSize: 20),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors
            .grey[300] // Slightly darker button background in light mode
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
