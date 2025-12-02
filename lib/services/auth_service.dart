import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, admin }

class AuthService extends ChangeNotifier {
  static const _keyLoggedIn = 'auth_logged_in';
  static const _keyEmail = 'auth_email';
  static const _keyRole = 'auth_role';

  bool _isInitialized = false;
  bool _loggedIn = false;
  String? _email;
  UserRole _role = UserRole.student;

  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _loggedIn;
  String? get email => _email;
  UserRole get role => _role;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    _email = prefs.getString(_keyEmail);
    final roleStr = prefs.getString(_keyRole) ?? 'student';
    _role = roleStr == 'admin' ? UserRole.admin : UserRole.student;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password, required UserRole role}) async {
    try {
      // Try Firebase Auth first
      final auth = FirebaseAuth.instance;
      UserCredential cred;
      try {
        cred = await auth.signInWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // Check if user exists in Firestore (created by admin)
          final existingUsers = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

          if (existingUsers.docs.isEmpty) {
            throw Exception('No account found. Please contact admin to create your account.');
          }

          // User exists in Firestore but not in Auth - create Auth account
          cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
          
          // Update Firestore user with uid
          await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).update({
            'uid': cred.user!.uid,
          });
        } else if (e.code == 'wrong-password') {
          rethrow;
        } else {
          // Fallback to local if Firebase not configured
          throw Exception('Firebase not ready');
        }
      }

      // Read user data from Firestore
      final snap = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
      final userData = snap.data();
      
      if (userData == null) {
        throw Exception('User data not found');
      }

      final isActive = userData['isActive'] as bool? ?? true;
      if (!isActive) {
        await auth.signOut();
        throw Exception('Your account has been deactivated. Please contact admin.');
      }

      final roleStr = userData['role'] as String? ?? role.name;
      _email = email;
      _role = roleStr == 'admin' ? UserRole.admin : UserRole.student;
      _loggedIn = true;
    } catch (e) {
      // If it's our custom error, rethrow
      if (e is Exception) rethrow;
      
      // Local auth fallback
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLoggedIn, true);
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyRole, role.name);
      _loggedIn = true;
      _email = email;
      _role = role;
    }
    notifyListeners();
  }

  Future<void> continueAsGuest(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyEmail, 'guest@local');
    await prefs.setString(_keyRole, role.name);
    _loggedIn = true;
    _email = 'guest@local';
    _role = role;
    notifyListeners();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyRole);
    _loggedIn = false;
    _email = null;
    _role = UserRole.student;
    notifyListeners();
  }
}
