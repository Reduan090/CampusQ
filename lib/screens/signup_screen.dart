import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String? _gender;
  String? _country;
  String? _pictureBase64;
  PlatformFile? _pickedFile;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _gender == null || _country == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    try {
      await auth.signUp(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        name: _nameCtrl.text.trim(),
        studentId: _idCtrl.text.trim(),
        department: _deptCtrl.text.trim(),
        bloodGroup: _bloodCtrl.text.trim(),
        contactNumber: _contactCtrl.text.trim(),
        gender: _gender ?? '',
        country: _country ?? '',
        picturePath: null,
      );
      if (_pickedFile != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          Uint8List bytes;
          if (_pickedFile!.bytes != null) {
            bytes = _pickedFile!.bytes!;
          } else if (_pickedFile!.readStream != null) {
            final chunks = <int>[];
            await for (final chunk in _pickedFile!.readStream!) {
              chunks.addAll(chunk);
            }
            bytes = Uint8List.fromList(chunks);
          } else {
            throw Exception('Cannot read selected file');
          }
          _pictureBase64 = bytes.isNotEmpty ? base64Encode(bytes) : null;
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'profilePictureBase64': _pictureBase64,
            'updatedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Student Account')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_add_alt_1, color: Colors.amberAccent, size: 32),
                        const SizedBox(width: 10),
                        Text(
                          'Student Signup',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: Colors.white70)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Name required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _idCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Student ID (e.g., 221-50-000)', labelStyle: TextStyle(color: Colors.white70)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'ID required';
                        final re = RegExp(r'^\d{3}-\d{2}-\d{3}$');
                        if (!re.hasMatch(v)) return 'Use format 221-50-000';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deptCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Department', labelStyle: TextStyle(color: Colors.white70)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Department required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bloodCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Blood Group', labelStyle: TextStyle(color: Colors.white70)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Blood group required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.white70)),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Colors.white70)),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Contact Number', labelStyle: TextStyle(color: Colors.white70)),
                      validator: (v) => (v == null || v.isEmpty) ? 'Contact number required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      items: ['Male', 'Female', 'Other']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) => setState(() => _gender = val),
                      decoration: const InputDecoration(labelText: 'Gender', labelStyle: TextStyle(color: Colors.white70)),
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                      validator: (v) => (v == null || v.isEmpty) ? 'Gender required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _country,
                      items: ['Bangladesh', 'India', 'Pakistan', 'Other']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setState(() => _country = val),
                      decoration: const InputDecoration(labelText: 'Country', labelStyle: TextStyle(color: Colors.white70)),
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                      validator: (v) => (v == null || v.isEmpty) ? 'Country required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _pickedFile == null ? 'No profile picture selected' : 'Selected: ${_pickedFile!.name}',
                            style: TextStyle(color: Colors.white.withOpacity(0.8)),
                          ),
                        ),
                        TextButton(
                          onPressed: _loading ? null : _pickPicture,
                          child: const Text('Choose Picture'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPicture() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withReadStream: true);
      if (result == null || result.files.isEmpty) return;
      setState(() {
        _pickedFile = result.files.first;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Picture selected. Will upload after signup')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selection failed: $e')),
      );
    }
  }
}