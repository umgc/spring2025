import 'dart:collection';
import 'caregiver_task_model.dart';

class CaregiverTaskService {
  final List<CaregiverTask> _tasks = [];

  UnmodifiableListView<CaregiverTask> get tasks => UnmodifiableListView(_tasks);

  void addTask(CaregiverTask task) {
    _tasks.add(task);
  }

  void updateTask(String id, CaregiverTask updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = updatedTask;
    }
  }

  CaregiverTask? getTaskById(String id) {
    return _tasks.firstWhere(
      (task) => task.id == id,
      orElse: () => throw Exception('Task not found'),
    );
  }

  void removeTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
  }
}
