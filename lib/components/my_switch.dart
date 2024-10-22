import 'package:flutter/material.dart';

class MySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const MySwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.grey.shade800,
      inactiveThumbColor: Colors.grey.shade800,
      activeTrackColor: const Color(0xFF8CAEB7),
      inactiveTrackColor: const Color(0xFF8CAEB7),
    );
  }
}
