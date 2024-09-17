import 'package:all_in_one/components/my_switch.dart';
import 'package:all_in_one/components/theme_notifer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeNotifer = Provider.of<ThemeNotifer>(context);
    bool isSwitched = themeNotifer.isDark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Change to dark mode"),
                const SizedBox(width: 20.0),
                MySwitch(value: isSwitched, onChanged: (value){
                  themeNotifer.toggleThemes(value);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
