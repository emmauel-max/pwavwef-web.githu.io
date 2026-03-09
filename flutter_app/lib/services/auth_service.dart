// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      await _loadUserModel(user.uid);
      await _refreshFcmToken(user.uid);
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserModel(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('[AuthService] loadUserModel error: $e');
    }
  }

  Future<void> _refreshFcmToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).update({'fcmToken': token});
      }
      // Refresh token listener
      _messaging.onTokenRefresh.listen((newToken) {
        _db.collection('users').doc(uid).update({'fcmToken': newToken});
      });
    } catch (e) {
      debugPrint('[AuthService] FCM token error: $e');
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // null = success
    } on FirebaseAuthException catch (e) {
      return _humanReadableError(e.code);
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String school,
    required String program,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _db.collection('users').doc(cred.user!.uid).set({
        'userId': cred.user!.uid,
        'email': email,
        'name': name,
        'phone': phone,
        'school': school,
        'program': program,
        'role': 'student',
        'weeklyXp': 50,
        'userRank': 'Rookie 🥚',
        'streak': 0,
        'activeDays': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return _humanReadableError(e.code);
    }
  }

  Future<void> signOut() async => _auth.signOut();

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _humanReadableError(e.code);
    }
  }

  Future<void> updateProfile({String? name, String? phone, String? program, String? profilePic}) async {
    if (currentUser == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (program != null) updates['program'] = program;
    if (profilePic != null) updates['profilePic'] = profilePic;
    await _db.collection('users').doc(currentUser!.uid).update(updates);
    await _loadUserModel(currentUser!.uid);
    notifyListeners();
  }

  String _humanReadableError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'This email is already registered.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'too-many-requests': return 'Too many attempts. Please try again later.';
      default: return 'Something went wrong. Please try again.';
    }
  }
}
