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

  Future<void> signIn({required String email, required String password, UserRole role = UserRole.student}) async {
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
        debugPrint('🔍 Checking Firestore for UID: ${cred.user!.uid}');
        debugPrint('🔍 Email: $email');
        
        // Read user data from Firestore
        final snap = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
        final userData = snap.data();
        
        if (userData == null) {
          debugPrint('⚠️ No document found with UID as document ID');
          debugPrint('🔍 Searching by email: $email');
          
          // Try to find user by email in case document ID doesn't match UID
          final usersByEmail = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          
          debugPrint('📊 Found ${usersByEmail.docs.length} documents with email: $email');
          
          if (usersByEmail.docs.isNotEmpty) {
            // Found user document with matching email but wrong ID
            // Update the document to use correct UID as document ID
            final oldDoc = usersByEmail.docs.first;
            final oldData = oldDoc.data();
            
            debugPrint('✅ Found user document with ID: ${oldDoc.id}');
            debugPrint('🔧 Fixing document ID to match Auth UID: ${cred.user!.uid}');
            
            // Create new document with correct UID and ensure all required fields
            await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
              'uid': cred.user!.uid,
              'email': email,
              'role': oldData['role'] ?? 'student',
              'isActive': oldData['isActive'] ?? true,
              'name': oldData['name'] ?? email.split('@')[0],
              'studentId': oldData['studentId'] ?? 'N/A',
              'department': oldData['department'] ?? 'N/A',
              'bloodGroup': oldData['bloodGroup'] ?? 'N/A',
              'pictureUrl': oldData['pictureUrl'],
              'createdAt': oldData['createdAt'] ?? DateTime.now().toIso8601String(),
            });
            
            // Delete old document
            await oldDoc.reference.delete();
            
            debugPrint('✅ Successfully fixed user document ID');
          } else {
            // No document found at all: auto-create minimal profile
            debugPrint('🆕 Creating minimal user profile document for UID: ${cred.user!.uid}');
            await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
              'uid': cred.user!.uid,
              'email': email,
              'role': role.name,
              'isActive': true,
              'name': email.split('@')[0],
              'studentId': 'N/A',
              'department': 'N/A',
              'bloodGroup': 'N/A',
              'pictureUrl': null,
              'createdAt': DateTime.now().toIso8601String(),
            });
            debugPrint('✅ Minimal user profile created');
          }

          // Re-read the corrected/created document
          final newSnap = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
          final newUserData = newSnap.data()!;
          
          final isActive = newUserData['isActive'] as bool? ?? true;
          if (!isActive) {
            await auth.signOut();
            throw Exception('Your account has been deactivated. Please contact admin.');
          }

          final roleStr = newUserData['role'] as String? ?? role.name;
          _email = email;
          _role = roleStr == 'admin' ? UserRole.admin : UserRole.student;
          _loggedIn = true;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_keyLoggedIn, true);
          await prefs.setString(_keyEmail, email);
          await prefs.setString(_keyRole, _role.name);
          
          debugPrint('✅ User logged in successfully as ${_role.name}');
          notifyListeners();
          return;
        }
        
        // Accept minimal documents (e.g., only role present). Fill safe defaults if missing.
        final isActive = (userData['isActive'] as bool?) ?? true;
        final roleStr = (userData['role'] as String?) ?? role.name;
        final name = (userData['name'] as String?) ?? email.split('@').first;
        final studentId = (userData['studentId'] as String?) ?? 'N/A';
        final department = (userData['department'] as String?) ?? 'N/A';
        final bloodGroup = (userData['bloodGroup'] as String?) ?? 'N/A';
        final pictureUrl = userData['pictureUrl'];
        final createdAt = (userData['createdAt'] as String?) ?? DateTime.now().toIso8601String();
        if (!isActive) {
          await auth.signOut();
          throw Exception('Your account has been deactivated. Please contact admin.');
        }

        // If any profile fields are missing, silently backfill them
        final needsUpdate = userData['uid'] == null ||
            userData['email'] == null ||
            userData['name'] == null ||
            userData['studentId'] == null ||
            userData['department'] == null ||
            userData['bloodGroup'] == null ||
            userData['createdAt'] == null;

        if (needsUpdate) {
          await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
            'uid': cred.user!.uid,
            'email': email,
            'role': roleStr,
            'isActive': isActive,
            'name': name,
            'studentId': studentId,
            'department': department,
            'bloodGroup': bloodGroup,
            'pictureUrl': pictureUrl,
            'createdAt': createdAt,
          }, SetOptions(merge: true));
        }

        _email = email;
        _role = roleStr == 'admin' ? UserRole.admin : UserRole.student;
        _loggedIn = true;
        
        // Save to SharedPreferences for persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyLoggedIn, true);
        await prefs.setString(_keyEmail, email);
        await prefs.setString(_keyRole, _role.name);
      } else {
        throw Exception('Authentication failed. Please try again.');
      }
    } catch (e) {
      rethrow;
    }
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

  Future<void> signUp(String email, String password, {
    UserRole role = UserRole.student,
    String? name,
    String? studentId,
    String? department,
    String? bloodGroup,
    String? contactNumber,
    String? gender,
    String? country,
    String? picturePath,
  }) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;
      debugPrint('🆕 Firebase user created: $uid');

      // Create initial user profile in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'role': role.name,
        'isActive': true,
        'name': name ?? email.split('@')[0],
        'studentId': studentId ?? 'N/A',
        'department': department ?? 'N/A',
        'bloodGroup': bloodGroup ?? 'N/A',
        'contactNumber': contactNumber ?? 'N/A',
        'gender': gender ?? 'N/A',
        'country': country ?? 'N/A',
        'picturePath': picturePath,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Firestore user profile created: users/$uid');

      // Persist session
      _email = email;
      _role = role;
      _loggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLoggedIn, true);
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyRole, _role.name);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      String msg = 'Sign up failed';
      if (e.code == 'weak-password') msg = 'Password is too weak';
      if (e.code == 'email-already-in-use') msg = 'Email already in use';
      if (e.code == 'invalid-email') msg = 'Invalid email address';
      debugPrint('❌ SignUp error: ${e.code} - ${e.message}');
      throw Exception(msg);
    } catch (e) {
      debugPrint('❌ SignUp unexpected error: $e');
      throw Exception('Unexpected error during sign up');
    }
  }
}
