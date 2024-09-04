import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Task {
  final String title;
  final String type;
  final List<String>? days;
  final String? date;
  final String description;

  Task({
    required this.title,
    required this.type,
    this.days,
    this.date,
    required this.description,
  });

  Map<String, dynamic> toMap(String ownerEmail) {
    return {
      'title': title,
      'type': type,
      'days': days,
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
  String selectedType = '';
  DateTime? selectedDate;
  List<String> selectedDays = [];
  bool isDateEnabled = false;

  @override
  void dispose() {
    taskController1.dispose();
    taskController4.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!isDateEnabled) return;

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
      String? date;
      List<String>? days;

      if (selectedType == 'Weekly') {
        days = selectedDays;
      } else if (selectedType == 'Monthly' && selectedDate != null) {
        date = selectedDate!.toLocal().toString().split(' ')[0];
      }

      String description = taskController4.text;

      Task newTask = Task(
        title: title,
        type: type,
        days: days,
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
                value: selectedType.isEmpty ? null : selectedType,
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
                    isDateEnabled = selectedType == 'Monthly';
                    selectedDays.clear();
                  });
                },
              ),
            ),

            // Weekly Task: Select multiple days
            if (selectedType == 'Weekly')
              Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Select Days"),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        _buildDayCheckbox("Mon"),
                        _buildDayCheckbox("Tue"),
                        _buildDayCheckbox("Wed"),
                        _buildDayCheckbox("Thu"),
                        _buildDayCheckbox("Fri"),
                        _buildDayCheckbox("Sat"),
                        _buildDayCheckbox("Sun"),
                      ],
                    ),
                  ],
                ),
              ),

            // Choose Date (for Monthly task)
            if (selectedType == 'Monthly')
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

            SizedBox(height: 20),

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

  Widget _buildDayCheckbox(String day) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: selectedDays.contains(day),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                selectedDays.add(day);
              } else {
                selectedDays.remove(day);
              }
            });
          },
        ),
        Text(day),
      ],
    );
  }
}
