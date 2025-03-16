class Task {
  final String id;
  final String taskName;
  final String assignedTo; // STML user
  final String caregiverId; // Caregiver ID
  final DateTime dueDate;
  final String status; // Pending, Completed
  final String notes;

  Task({
    required this.id,
    required this.taskName,
    required this.assignedTo,
    required this.caregiverId,
    required this.dueDate,
    required this.status,
    required this.notes,
  });

  // Convert Task to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskName': taskName,
      'assignedTo': assignedTo,
      'caregiverId': caregiverId,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  // Create Task from Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      taskName: map['taskName'],
      assignedTo: map['assignedTo'],
      caregiverId: map['caregiverId'],
      dueDate: DateTime.parse(map['dueDate']),
      status: map['status'],
      notes: map['notes'],
    );
  }
}
