// lib/models/assignment.dart
class Assignment {
  final String id;
  final String userId;
  final String title;
  final String course;
  final String dueDate;
  final bool isCompleted;
  final int alertOffset;

  const Assignment({
    required this.id,
    required this.userId,
    required this.title,
    required this.course,
    required this.dueDate,
    this.isCompleted = false,
    this.alertOffset = 0,
  });

  factory Assignment.fromMap(String id, Map<String, dynamic> map) {
    return Assignment(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      course: map['course'] as String? ?? '',
      dueDate: map['dueDate'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      alertOffset: (map['alertOffset'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'course': course,
    'dueDate': dueDate,
    'isCompleted': isCompleted,
    'alertOffset': alertOffset,
  };

  Assignment copyWith({bool? isCompleted}) => Assignment(
    id: id,
    userId: userId,
    title: title,
    course: course,
    dueDate: dueDate,
    isCompleted: isCompleted ?? this.isCompleted,
    alertOffset: alertOffset,
  );
}
