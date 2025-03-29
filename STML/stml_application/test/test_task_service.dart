

import 'package:memoryminder/src/features/caregiver_task_management/model/caregiver_task_model.dart';
import 'package:memoryminder/src/features/caregiver_task_management/service/caregiver_task_service.dart';

void main() {
  final taskService = CaregiverTaskService();

  // Adding tasks
  final task1 = CaregiverTask(
    id: '1',
    taskName: 'Doctor Appointment',
    assignedTo: 'John Doe',
    caregiverId: 'C123',
    dueDate: DateTime.now().add(Duration(days: 2)),
    status: 'Pending',
    notes: 'Discuss medication schedule',
  );

  final task2 = CaregiverTask(
    id: '2',
    taskName: 'Buy groceries',
    assignedTo: 'Jane Smith',
    caregiverId: 'C124',
    dueDate: DateTime.now().add(Duration(days: 1)),
    status: 'Completed',
    notes: 'Get fruits and vegetables',
  );

  taskService.addTask(task1);
  taskService.addTask(task2);

  // Display tasks
  print('All Tasks:');
  for (var task in taskService.tasks) {
    print('Task: ${task.taskName}, Assigned to: ${task.assignedTo}');
  }

  // Update a task
  final updatedTask = CaregiverTask(
    id: '1',
    taskName: 'Doctor Visit',
    assignedTo: 'John Doe',
    caregiverId: 'C123',
    dueDate: DateTime.now().add(Duration(days: 3)),
    status: 'Rescheduled',
    notes: 'Check-up rescheduled',
  );
  taskService.updateTask('1', updatedTask);

  // Remove a task
  taskService.removeTask('2');

  // Get a task by ID
  final fetchedTask = taskService.getTaskById('1');
  print('Fetched Task: ${fetchedTask != null ? fetchedTask.taskName : 'Task not found'}');
}
