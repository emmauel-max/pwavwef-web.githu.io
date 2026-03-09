// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/assignment.dart';
import '../models/course.dart';
import '../models/note.dart';
import '../models/user_model.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── USERS ───────────────────────────────────────────────────────────────────

  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromMap(snap.data()!);
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ─── ASSIGNMENTS ─────────────────────────────────────────────────────────────

  Stream<List<Assignment>> streamAssignments() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('assignments')
        .where('userId', isEqualTo: _uid)
        .orderBy('dueDate')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Assignment.fromMap(d.id, d.data())).toList());
  }

  Future<void> addAssignment(Assignment a) async {
    await _db.collection('assignments').add(a.toMap());
  }

  Future<void> toggleAssignment(String id, bool currentStatus) async {
    await _db.collection('assignments').doc(id).update({
      'isCompleted': !currentStatus,
    });
  }

  Future<void> deleteAssignment(String id) async {
    await _db.collection('assignments').doc(id).delete();
  }

  // ─── COURSES ─────────────────────────────────────────────────────────────────

  Stream<List<Course>> streamCourses() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('courses')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Course.fromMap(d.id, d.data())).toList());
  }

  Future<void> addCourse(Course c) async {
    await _db.collection('courses').add(c.toMap());
  }

  Future<void> updateCourse(String id, Map<String, dynamic> data) async {
    await _db.collection('courses').doc(id).update(data);
  }

  Future<void> deleteCourse(String id) async {
    await _db.collection('courses').doc(id).delete();
  }

  // ─── NOTES ───────────────────────────────────────────────────────────────────

  Stream<List<Note>> streamNotes() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('notes')
        .where('userId', isEqualTo: _uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Note.fromMap(d.id, d.data())).toList());
  }

  Future<void> addNote(Note n) async {
    await _db.collection('notes').add(n.toMap());
  }

  Future<void> updateNote(String id, Note n) async {
    await _db.collection('notes').doc(id).update(n.toMap());
  }

  Future<void> deleteNote(String id) async {
    await _db.collection('notes').doc(id).delete();
  }

  // ─── XP & STREAK ─────────────────────────────────────────────────────────────

  static const _ranks = [
    (0, 'Rookie 🥚'),
    (100, 'Scholar 📚'),
    (300, 'Main Character ✨'),
    (600, 'Academic Weapon ⚔️'),
    (1000, 'God Tier ⚡'),
  ];

  String _rankForXp(int xp) {
    String rank = _ranks.first.$2;
    for (final r in _ranks) {
      if (xp >= r.$1) rank = r.$2;
    }
    return rank;
  }

  Future<void> addXp(int amount) async {
    if (_uid == null) return;
    final docRef = _db.collection('users').doc(_uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final current = (snap.data()?['weeklyXp'] as num?)?.toInt() ?? 0;
      final newXp = current + amount;
      tx.update(docRef, {
        'weeklyXp': newXp,
        'userRank': _rankForXp(newXp),
      });
    });
  }

  Future<void> updateStreak() async {
    if (_uid == null) return;
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final docRef = _db.collection('users').doc(_uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final lastDate = data['lastStreakDate'] as String?;
      final currentStreak = (data['streak'] as num?)?.toInt() ?? 0;
      List<String> activeDays = List<String>.from(data['activeDays'] as List? ?? []);

      if (lastDate == dateStr) return; // Already logged today

      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final newStreak = lastDate == yesterdayStr ? currentStreak + 1 : 1;
      if (!activeDays.contains(dateStr)) activeDays.add(dateStr);

      tx.update(docRef, {
        'streak': newStreak,
        'lastStreakDate': dateStr,
        'activeDays': activeDays,
        'weeklyXp': FieldValue.increment(10), // Daily login bonus
      });
    });
  }
}
