// lib/models/course.dart
class Course {
  final String id;
  final String userId;
  final String name;
  final String venue;
  final String day;
  final String time;
  final int alertOffset;

  const Course({
    required this.id,
    required this.userId,
    required this.name,
    required this.venue,
    required this.day,
    required this.time,
    this.alertOffset = 0,
  });

  factory Course.fromMap(String id, Map<String, dynamic> map) {
    return Course(
      id: id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      venue: map['venue'] as String? ?? '',
      day: map['day'] as String? ?? 'Monday',
      time: map['time'] as String? ?? '08:00',
      alertOffset: (map['alertOffset'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'venue': venue,
    'day': day,
    'time': time,
    'alertOffset': alertOffset,
  };
}
