import 'package:flutter/material.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {

  int number_of_daily = 1;
  int number_of_weekly = 1;
  int number_of_monthly = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          "To Do",
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
        actions: [
          IconButton(
              onPressed: () => {},
              icon: Icon(Icons.calendar_today_rounded)
          ),
          IconButton(
              onPressed: () => {},
              icon: Icon(Icons.add)
          )
        ],
      ),
      body: ListView(
        children: [
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.all(10),
                  child: Text("Daily Task"),
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.inversePrimary
                      )
                  ),
                  margin: EdgeInsets.all(10),
                  width: 400, height: number_of_daily * 50,
                  child: Center(
                      child: Text("There is no task now T^T")
                  ),
                ),
              ],
            ),
          ),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.all(10),
                  child: Text("Weekly Task"),
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.inversePrimary
                      )
                  ),
                  margin: EdgeInsets.all(10),
                  width: 400, height: number_of_weekly * 50,
                  child: Center(
                        child: Text("There is no task now T^T")
                  ),
                ),
              ],
            ),
          ),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.all(10),
                  child: Text("Monthly Task"),
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.inversePrimary
                      )
                  ),
                  margin: EdgeInsets.all(10),
                  width: 400, height: number_of_monthly * 50,
                  child: Center(
                      child: Text("There is no task now T^T")
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
