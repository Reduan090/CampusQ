import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore? _firestore;
  final List<UserModel> _users = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;

  UserService({FirebaseFirestore? firestore}) : _firestore = firestore {
    if (_firestore != null) {
      _listenToUsers();
    }
  }

  List<UserModel> get users => List.unmodifiable(_users);

  List<UserModel> get activeUsers =>
      _users.where((u) => u.isActive).toList();

  List<UserModel> get inactiveUsers =>
      _users.where((u) => !u.isActive).toList();

  UserModel? getUserById(String uid) {
    try {
      return _users.firstWhere((u) => u.uid == uid);
    } catch (e) {
      return null;
    }
  }

  void _listenToUsers() {
    _usersSub = _firestore!.collection('users').snapshots().listen((snapshot) {
      _users.clear();
      for (final doc in snapshot.docs) {
        try {
          _users.add(UserModel.fromMap(doc.data()));
        } catch (e) {
          debugPrint('Error parsing user: $e');
        }
      }
      notifyListeners();
    });
  }

  Future<void> createUser({
    required String email,
    required String uid,
    required String role,
    String? name,
    String? studentId,
    String? department,
    String? bloodGroup,
    bool isActive = true,
  }) async {
    if (_firestore == null) return;

    final user = UserModel(
      uid: uid,
      email: email,
      role: role,
      isActive: isActive,
      name: name,
      studentId: studentId,
      department: department,
      bloodGroup: bloodGroup,
    );

    await _firestore!.collection('users').doc(uid).set(user.toMap());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    if (_firestore == null) return;
    await _firestore!.collection('users').doc(uid).update(updates);
  }

  Future<void> activateUser(String uid) async {
    await updateUser(uid, {'isActive': true});
  }

  Future<void> deactivateUser(String uid) async {
    await updateUser(uid, {'isActive': false});
  }

  Future<void> deleteUser(String uid) async {
    if (_firestore == null) return;
    await _firestore!.collection('users').doc(uid).delete();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }
}
