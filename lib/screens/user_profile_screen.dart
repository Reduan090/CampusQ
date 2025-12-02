import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _pictureUrlController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authService = context.read<AuthService>();
    final userService = context.read<UserService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final user = userService.getUserById(uid);
      if (user != null) {
        _nameController.text = user.name ?? '';
        _studentIdController.text = user.studentId ?? '';
        _departmentController.text = user.department ?? '';
        _bloodGroupController.text = user.bloodGroup ?? '';
        _pictureUrlController.text = user.pictureUrl ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    _bloodGroupController.dispose();
    _pictureUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userService = context.watch<UserService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final user = uid != null ? userService.getUserById(uid) : null;

    return Scaffold(
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: user.pictureUrl != null && user.pictureUrl!.isNotEmpty
                              ? NetworkImage(user.pictureUrl!)
                              : null,
                          child: user.pictureUrl == null || user.pictureUrl!.isEmpty
                              ? Text(
                                  user.name?.substring(0, 1).toUpperCase() ??
                                      user.email.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.name ?? user.email,
                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(user.role.toUpperCase()),
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile Information',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: Icon(_isEditing ? Icons.check : Icons.edit),
                        onPressed: () {
                          if (_isEditing) {
                            _saveProfile();
                          } else {
                            setState(() => _isEditing = true);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProfileField(
                    label: 'Name',
                    controller: _nameController,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _buildProfileField(
                    label: 'Student ID',
                    controller: _studentIdController,
                    icon: Icons.badge,
                  ),
                  const SizedBox(height: 12),
                  _buildProfileField(
                    label: 'Department',
                    controller: _departmentController,
                    icon: Icons.school,
                  ),
                  const SizedBox(height: 12),
                  _buildProfileField(
                    label: 'Blood Group',
                    controller: _bloodGroupController,
                    icon: Icons.bloodtype,
                  ),
                  const SizedBox(height: 12),
                  _buildProfileField(
                    label: 'Picture URL',
                    controller: _pictureUrlController,
                    icon: Icons.image,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final userService = context.read<UserService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    try {
      await userService.updateUser(uid, {
        'name': _nameController.text.isEmpty ? null : _nameController.text,
        'studentId': _studentIdController.text.isEmpty ? null : _studentIdController.text,
        'department': _departmentController.text.isEmpty ? null : _departmentController.text,
        'bloodGroup': _bloodGroupController.text.isEmpty ? null : _bloodGroupController.text,
        'pictureUrl': _pictureUrlController.text.isEmpty ? null : _pictureUrlController.text,
      });

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }
}
