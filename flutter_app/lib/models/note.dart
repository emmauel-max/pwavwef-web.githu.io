// lib/models/note.dart
class Note {
  final String id;
  final String userId;
  final String title;
  final String subtitle;
  final String body;
  final int updatedAt;

  const Note({
    required this.id,
    required this.userId,
    required this.title,
    this.subtitle = '',
    this.body = '',
    required this.updatedAt,
  });

  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      body: map['body'] as String? ?? '',
      updatedAt: (map['updatedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'subtitle': subtitle,
    'body': body,
    'updatedAt': updatedAt,
  };

  Note copyWith({String? title, String? subtitle, String? body}) => Note(
    id: id,
    userId: userId,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    body: body ?? this.body,
    updatedAt: DateTime.now().millisecondsSinceEpoch,
  );
}
