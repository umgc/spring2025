import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class CaregiverTaskScreen extends StatefulWidget {
  @override
  _CaregiverTaskScreenState createState() => _CaregiverTaskScreenState();
}

class _CaregiverTaskScreenState extends State<CaregiverTaskScreen> {
  final TaskService _taskService = TaskService();
  final TextEditingController _taskController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final tasks = _taskService.getTasks();

    return Scaffold(
      appBar: AppBar(
        title: Text('Caregiver - Task Management'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _taskController,
              decoration: InputDecoration(
                labelText: 'Task Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    final task = Task(
                      id: DateTime.now().toString(),
                      taskName: _taskController.text,
                      assignedTo: 'STML User 1',
                      caregiverId: 'Caregiver 1',
                      dueDate: DateTime.now().add(Duration(days: 1)),
                      status: 'Pending',
                      notes: 'Sample task',
                    );
                    _taskService.addTask(task);
                    setState(() {});
                    _taskController.clear();
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text(task.taskName),
                  subtitle: Text('Due: ${task.dueDate} - Status: ${task.status}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _taskService.deleteTask(task.id);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
