import 'package:flutter/material.dart';

class MyFloatingActionButton extends StatelessWidget {
  final void Function()? onPressed;
  final Widget child;

  const MyFloatingActionButton({super.key, required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      onPressed: onPressed,
      child: child,
    );
  }
}
