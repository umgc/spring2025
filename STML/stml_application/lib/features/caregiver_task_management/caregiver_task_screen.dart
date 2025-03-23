import 'package:flutter/material.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/app_bar.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'caregiver_task_service.dart';
import 'caregiver_task_model.dart';

class CaregiverTaskScreen extends StatefulWidget {
  @override
  _CaregiverTaskScreenState createState() => _CaregiverTaskScreenState();
}

class _CaregiverTaskScreenState extends State<CaregiverTaskScreen> {
  final CaregiverTaskService _taskService = CaregiverTaskService();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _assignedToController = TextEditingController();
  DateTime? _selectedDueDate;
  String _selectedStatus = 'Pending';
  final List<String> _statusOptions = ['Pending', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    _taskService.addTask(CaregiverTask(
      id: '1',
      taskName: 'Doctor Appointment',
      assignedTo: 'John Doe',
      caregiverId: 'C123',
      dueDate: DateTime.now().add(Duration(days: 2)),
      status: 'Pending',
      notes: 'Discuss medication schedule',
    ));

    _taskService.addTask(CaregiverTask(
      id: '2',
      taskName: 'Buy groceries',
      assignedTo: 'Jane Smith',
      caregiverId: 'C124',
      dueDate: DateTime.now().add(Duration(days: 1)),
      status: 'Completed',
      notes: 'Get fruits and vegetables',
    ));
  }

  // Date Picker
  Future<void> _pickDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDueDate) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
    }
  }

  // Add Task Dialog
  void _showAddTaskDialog() {
    _taskNameController.clear();
    _assignedToController.clear();
    _selectedDueDate = null;
    _selectedStatus = 'Pending';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _taskNameController,
                  decoration: InputDecoration(labelText: 'Task Name'),
                ),
                TextField(
                  controller: _assignedToController,
                  decoration: InputDecoration(labelText: 'Assigned To'),
                ),
                ListTile(
                  title: Text(
                    _selectedDueDate == null
                        ? 'Pick Due Date'
                        : 'Due Date: ${_selectedDueDate!.toLocal()}'.split(' ')[0],
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () => _pickDueDate(context),
                ),
                DropdownButtonFormField(
                  value: _selectedStatus,
                  items: _statusOptions.map((String status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addTask();
                Navigator.pop(context);
              },
              child: Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  void _addTask() {
    final newTask = CaregiverTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskName: _taskNameController.text,
      assignedTo: _assignedToController.text,
      caregiverId: 'C999',
      dueDate: _selectedDueDate ?? DateTime.now(),
      status: _selectedStatus,
      notes: 'No notes yet',
    );

    setState(() {
      _taskService.addTask(newTask);
    });
  }

  // Edit Task Dialog
  void _showEditTaskDialog(CaregiverTask task) {
    _taskNameController.text = task.taskName;
    _assignedToController.text = task.assignedTo;
    _selectedDueDate = task.dueDate;
    _selectedStatus = task.status;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _taskNameController,
                  decoration: InputDecoration(labelText: 'Task Name'),
                ),
                TextField(
                  controller: _assignedToController,
                  decoration: InputDecoration(labelText: 'Assigned To'),
                ),
                ListTile(
                  title: Text(
                    _selectedDueDate == null
                        ? 'Pick Due Date'
                        : 'Due Date: ${_selectedDueDate!.toLocal()}'.split(' ')[0],
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () => _pickDueDate(context),
                ),
                DropdownButtonFormField(
                  value: _selectedStatus,
                  items: _statusOptions.map((String status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _editTask(task.id);
                Navigator.pop(context);
              },
              child: Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _editTask(String id) {
    final updatedTask = CaregiverTask(
      id: id,
      taskName: _taskNameController.text,
      assignedTo: _assignedToController.text,
      caregiverId: 'C123',
      dueDate: _selectedDueDate ?? DateTime.now(),
      status: _selectedStatus,
      notes: 'Updated notes',
    );

    setState(() {
      _taskService.updateTask(id, updatedTask);
    });
  }

  // Remove Task
  void _removeTask(String id) {
    setState(() {
      _taskService.removeTask(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Tasks',
      ),
      body: ListView.builder(
        itemCount: _taskService.tasks.length,
        itemBuilder: (context, index) {
          final task = _taskService.tasks[index];
          return Card(
            child: ListTile(
              title: Text(task.taskName),
              subtitle: Text(
                  'Assigned to: ${task.assignedTo}\nDue: ${task.dueDate.toLocal()}'.split(' ')[0] +
                  '\nStatus: ${task.status}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditTaskDialog(task),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeTask(task.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Task',
      ),
        bottomNavigationBar: UiUtils.createBottomNavigationBar(context));

  }
}
