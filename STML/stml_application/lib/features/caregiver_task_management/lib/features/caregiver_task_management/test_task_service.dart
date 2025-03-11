import 'caregiver_task_model.dart';
import 'caregiver_task_service.dart';

void main() {
  final taskService = CaregiverTaskService();

  final task1 = CaregiverTask(
    id: '1',
    taskName: 'Doctor Appointment',
    assignedTo: 'John Doe',
    caregiverId: 'caregiver_1',
    dueDate: DateTime.now(),
    status: 'Pending',
    notes: 'Bring medical documents',
  );

  taskService.addTask(task1);

  print('All Tasks:');
  taskService.tasks.forEach((task) {
    print('Task: ${task.taskName}, Assigned to: ${task.assignedTo}');
  });

  final updatedTask = CaregiverTask(
    id: '1',
    taskName: 'Updated Doctor Appointment',
    assignedTo: 'John Doe',
    caregiverId: 'caregiver_1',
    dueDate: DateTime.now(),
    status: 'Completed',
    notes: 'Appointment rescheduled',
  );

  taskService.updateTask('1', updatedTask);
  taskService.deleteTask('1');

  print('Tasks after deletion: ${taskService.tasks.length}');
}
