import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Task {
  final String title;
  final String type;
  final String? date;
  final String description;

  Task({
    required this.title,
    required this.type,
    this.date,
    required this.description,
  });

  Map<String, dynamic> toMap(String ownerEmail) {
    return {
      'title': title,
      'type': type,
      'date': date,
      'description': description,
      'owner': ownerEmail,
    };
  }
}

class AddingTaskPage extends StatefulWidget {
  const AddingTaskPage({super.key});

  @override
  State<AddingTaskPage> createState() => _AddingTaskPageState();
}

class _AddingTaskPageState extends State<AddingTaskPage> {
  final TextEditingController taskController1 = TextEditingController();
  final TextEditingController taskController4 = TextEditingController();
  String selectedType = 'Daily';
  DateTime? selectedDate;

  @override
  void dispose() {
    taskController1.dispose();
    taskController4.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String title = taskController1.text;
      String type = selectedType;
      String? date = selectedDate != null ? selectedDate!.toLocal().toString().split(' ')[0] : null;
      String description = taskController4.text;

      Task newTask = Task(
        title: title,
        type: type,
        date: date,
        description: description,
      );

      await FirebaseFirestore.instance.collection('tasks').add(newTask.toMap(user.email!));

      Navigator.pop(context, newTask);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: You must be logged in to save a task.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Task')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Write Title
            Container(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: taskController1,
                decoration: InputDecoration(labelText: "Title"),
              ),
            ),

            // Select Type: Daily, Weekly, Monthly
            Container(
              padding: EdgeInsets.all(10),
              child: DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(labelText: "Choose Type"),
                items: <String>['Daily', 'Weekly', 'Monthly'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedType = newValue!;
                  });
                },
              ),
            ),

            // Choose Date
            Container(
              padding: EdgeInsets.all(10),
              child: InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Select Date',
                  ),
                  child: Text(
                    selectedDate != null
                        ? "${selectedDate!.toLocal()}".split(' ')[0]
                        : 'No Date Chosen',
                  ),
                ),
              ),
            ),

            // Write Description
            Container(
              padding: EdgeInsets.all(10),
              child: TextField(
                controller: taskController4,
                decoration: InputDecoration(labelText: "Description"),
              ),
            ),

            SizedBox(height: 20),

            // Save Button: Save and go back
            ElevatedButton(
              onPressed: _saveTask,
              child: Text("Save Task"),
            ),
          ],
        ),
      ),
    );
  }
}
