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
      UserCredential? cred;
      
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
          final firstDoc = existingUsers.docs.first;
          await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
            ...firstDoc.data(),
            'uid': cred.user!.uid,
          });
          await FirebaseFirestore.instance.collection('users').doc(firstDoc.id).delete();
        } else if (e.code == 'wrong-password') {
          throw Exception('Incorrect password. Please try again.');
        } else if (e.code == 'invalid-email') {
          throw Exception('Invalid email format.');
        } else {
          // Fallback to local auth if Firebase not configured properly
          debugPrint('Firebase error: ${e.code} - ${e.message}');
          cred = null; // Explicitly set to null to trigger local auth
        }
      }

      // If Firebase auth succeeded, process Firestore data
      if (cred != null) {
        // Read user data from Firestore
        final snap = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
        final userData = snap.data();
        
        if (userData == null) {
          // Create user document if it doesn't exist
          await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
            'uid': cred.user!.uid,
            'email': email,
            'role': role.name,
            'isActive': true,
            'createdAt': DateTime.now().toIso8601String(),
          });
          
          _email = email;
          _role = role;
          _loggedIn = true;
        } else {
          final isActive = userData['isActive'] as bool? ?? true;
          if (!isActive) {
            await auth.signOut();
            throw Exception('Your account has been deactivated. Please contact admin.');
          }

          final roleStr = userData['role'] as String? ?? role.name;
          _email = email;
          _role = roleStr == 'admin' ? UserRole.admin : UserRole.student;
          _loggedIn = true;
        }
        
        // Save to SharedPreferences for persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyLoggedIn, true);
        await prefs.setString(_keyEmail, email);
        await prefs.setString(_keyRole, _role.name);
      } else {
        // Firebase not available, trigger local auth fallback
        throw Exception('Firebase unavailable');
      }
      
    } catch (e) {
      // If it's our custom error, rethrow
      if (e.toString().contains('No account found') || 
          e.toString().contains('deactivated') ||
          e.toString().contains('Incorrect password') ||
          e.toString().contains('Invalid email')) {
        rethrow;
      }
      
      // Local auth fallback for demo purposes
      debugPrint('Falling back to local auth: $e');
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
