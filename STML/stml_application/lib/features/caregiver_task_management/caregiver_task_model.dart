class CaregiverTask {
  final String id;
  final String taskName;
  final String assignedTo;
  final String caregiverId;
  final DateTime dueDate;
  final String status;
  final String notes;

  CaregiverTask({
    required this.id,
    required this.taskName,
    required this.assignedTo,
    required this.caregiverId,
    required this.dueDate,
    required this.status,
    required this.notes,
  });
}
