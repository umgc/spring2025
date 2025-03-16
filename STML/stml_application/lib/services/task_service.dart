import '../models/task_model.dart';

class TaskService {
  final List<Task> _tasks = [];

  // Add a new task
  void addTask(Task task) {
    _tasks.add(task);
  }

  // Get all tasks
  List<Task> getTasks() {
    return _tasks;
  }

  // Update a task by id
  void updateTask(String id, Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = updatedTask;
    }
  }

  // Delete a task by id
  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
  }
}
