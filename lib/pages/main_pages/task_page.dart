import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'adding_task_page.dart';

class Task {
  final String title;
  final String type;
  final String? date;
  final String description;
  final List<String>? days;
  bool isCompleted;

  Task({
    required this.title,
    required this.type,
    this.date,
    required this.description,
    this.days,
    this.isCompleted = false,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Task(
      title: data['title'],
      type: data['type'],
      date: data['date'],
      description: data['description'],
      days: List<String>.from(data['days'] ?? []),
      isCompleted: data['isCompleted'] ?? false,
    );
  }
}

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  List<Task> dailyTasks = [];
  List<Task> weeklyTasks = [];
  List<Task> monthlyTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userEmail = user.email;

      FirebaseFirestore.instance
          .collection('tasks')
          .where('owner', isEqualTo: userEmail)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          dailyTasks.clear();
          weeklyTasks.clear();
          monthlyTasks.clear();

          for (var doc in snapshot.docs) {
            var task = Task.fromFirestore(doc);

            if (task.type == 'Daily') {
              dailyTasks.add(task);
            } else if (task.type == 'Weekly') {
              weeklyTasks.add(task);
            } else if (task.type == 'Monthly') {
              monthlyTasks.add(task);
            }
          }
        });
      });
    }
  }

  void _addTask(Task task) {
    setState(() {
      if (task.type == 'Daily') {
        dailyTasks.add(task);
      } else if (task.type == 'Weekly') {
        weeklyTasks.add(task);
      } else if (task.type == 'Monthly') {
        monthlyTasks.add(task);
      }
    });
  }

  void _deleteTask(Task task) {
    FirebaseFirestore.instance
        .collection('tasks')
        .where('title', isEqualTo: task.title)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });
    setState(() {
      if (task.type == 'Daily') {
        dailyTasks.remove(task);
      } else if (task.type == 'Weekly') {
        weeklyTasks.remove(task);
      } else if (task.type == 'Monthly') {
        monthlyTasks.remove(task);
      }
    });
  }

  void _updateTaskCompletion(Task task, bool isCompleted) {
    FirebaseFirestore.instance
        .collection('tasks')
        .where('title', isEqualTo: task.title)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'isCompleted': isCompleted});
      }
    });
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.background,
          title: Text(
            task.title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show task type and details (days or date)
              Text(
                task.type == 'Weekly'
                    ? "Days: ${task.days?.join(', ') ?? 'No days selected'}"
                    : "Date: ${task.date ?? 'No date selected'}",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 10),
              // Show task description
              Text(
                "Description: ${task.description}",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          actions: [
            // Close button
            TextButton(
              child: Text(
                "Close",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8CAEB7),
        title: Text(
          "To Do",
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontSize: 25,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddingTaskPage(),
                ),
              );
              if (result != null && result is Task) {
                _addTask(result);
              }
            },
            icon: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          )
        ],
      ),
      body: ListView(
        children: [
          _buildTaskSection("Daily Task", dailyTasks),
          _buildTaskSection("Weekly Task", weeklyTasks),
          _buildTaskSection("Monthly Task", monthlyTasks),
        ],
      ),
    );
  }

  Widget _buildTaskSection(String title, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.all(10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 24), // Increase font size
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          margin: const EdgeInsets.all(10),
          width: 400,
          child: tasks.isNotEmpty
              ? Column(
            children: tasks.map((task) {
              return ListTile(
                leading: Checkbox(
                  value: task.isCompleted,
                  onChanged: (bool? value) {
                    setState(() {
                      task.isCompleted = value!;
                      _updateTaskCompletion(task, value);
                    });
                  },
                ),
                title: Text(task.title),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    _deleteTask(task);
                  },
                ),
                onTap: () {
                  _showTaskDetails(context, task);
                },
              );
            }).toList(),
          )
              : const Center(
            child: Text(
              "Add Task",
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ],
    );
  }
}


