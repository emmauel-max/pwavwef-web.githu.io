// lib/models/user_model.dart
class UserModel {
  final String userId;
  final String email;
  final String name;
  final String phone;
  final String school;
  final String program;
  final String role;
  final int weeklyXp;
  final String userRank;
  final int streak;
  final String? profilePic;
  final List<String> activeDays;
  final String? fcmToken;

  const UserModel({
    required this.userId,
    required this.email,
    required this.name,
    required this.phone,
    required this.school,
    required this.program,
    this.role = 'student',
    this.weeklyXp = 0,
    this.userRank = 'Rookie 🥚',
    this.streak = 0,
    this.profilePic,
    this.activeDays = const [],
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      school: map['school'] as String? ?? '',
      program: map['program'] as String? ?? '',
      role: map['role'] as String? ?? 'student',
      weeklyXp: (map['weeklyXp'] as num?)?.toInt() ?? 0,
      userRank: map['userRank'] as String? ?? 'Rookie 🥚',
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      profilePic: map['profilePic'] as String?,
      activeDays: List<String>.from(map['activeDays'] as List? ?? []),
      fcmToken: map['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'email': email,
    'name': name,
    'phone': phone,
    'school': school,
    'program': program,
    'role': role,
    'weeklyXp': weeklyXp,
    'userRank': userRank,
    'streak': streak,
    if (profilePic != null) 'profilePic': profilePic,
    'activeDays': activeDays,
    if (fcmToken != null) 'fcmToken': fcmToken,
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? program,
    String? profilePic,
    int? weeklyXp,
    String? userRank,
    int? streak,
    List<String>? activeDays,
    String? fcmToken,
  }) {
    return UserModel(
      userId: userId,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      school: school,
      program: program ?? this.program,
      role: role,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      userRank: userRank ?? this.userRank,
      streak: streak ?? this.streak,
      profilePic: profilePic ?? this.profilePic,
      activeDays: activeDays ?? this.activeDays,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
