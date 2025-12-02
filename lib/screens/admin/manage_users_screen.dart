import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final users = _showInactive ? userService.inactiveUsers : userService.activeUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Export PDF',
            onPressed: () => _exportUsersPdf(context, userService.users),
          ),
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: _showInactive ? 'Show Active' : 'Show Inactive',
            onPressed: () => setState(() => _showInactive = !_showInactive),
          ),
        ],
      ),
      body: users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _showInactive ? 'No inactive users' : 'No active users',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user.isActive
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
                      child: Text(
                        user.name?.substring(0, 1).toUpperCase() ?? user.email.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: user.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(user.name ?? user.email),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        if (user.studentId != null) Text('ID: ${user.studentId}'),
                        if (user.department != null) Text('Dept: ${user.department}'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'activate':
                            userService.activateUser(user.uid);
                            break;
                          case 'deactivate':
                            userService.deactivateUser(user.uid);
                            break;
                          case 'edit':
                            _showEditUserDialog(context, userService, user);
                            break;
                          case 'delete':
                            _showDeleteDialog(context, userService, user);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (!user.isActive)
                          const PopupMenuItem(
                            value: 'activate',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 20),
                                SizedBox(width: 8),
                                Text('Activate'),
                              ],
                            ),
                          ),
                        if (user.isActive)
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: Row(
                              children: [
                                Icon(Icons.block, size: 20),
                                SizedBox(width: 8),
                                Text('Deactivate'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final studentIdController = TextEditingController();
    final departmentController = TextEditingController();
    final bloodGroupController = TextEditingController();
    String role = 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'user@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: studentIdController,
                  decoration: const InputDecoration(labelText: 'Student ID'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bloodGroupController,
                  decoration: const InputDecoration(labelText: 'Blood Group'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) => setState(() => role = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email is required')),
                  );
                  return;
                }

                final userService = context.read<UserService>();
                final uid = 'user_${DateTime.now().millisecondsSinceEpoch}';

                await userService.createUser(
                  email: emailController.text,
                  uid: uid,
                  role: role,
                  name: nameController.text.isEmpty ? null : nameController.text,
                  studentId: studentIdController.text.isEmpty ? null : studentIdController.text,
                  department: departmentController.text.isEmpty ? null : departmentController.text,
                  bloodGroup: bloodGroupController.text.isEmpty ? null : bloodGroupController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User created successfully')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, UserService service, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final studentIdController = TextEditingController(text: user.studentId);
    final departmentController = TextEditingController(text: user.department);
    final bloodGroupController = TextEditingController(text: user.bloodGroup);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: studentIdController,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: departmentController,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bloodGroupController,
                decoration: const InputDecoration(labelText: 'Blood Group'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await service.updateUser(user.uid, {
                'name': nameController.text.isEmpty ? null : nameController.text,
                'studentId': studentIdController.text.isEmpty ? null : studentIdController.text,
                'department': departmentController.text.isEmpty ? null : departmentController.text,
                'bloodGroup': bloodGroupController.text.isEmpty ? null : bloodGroupController.text,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, UserService service, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name ?? user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await service.deleteUser(user.uid);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportUsersPdf(BuildContext context, List<UserModel> users) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'User Directory',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Name', 'Email', 'Student ID', 'Department', 'Blood Group', 'Status'],
                data: users.map((user) => [
                  user.name ?? '-',
                  user.email,
                  user.studentId ?? '-',
                  user.department ?? '-',
                  user.bloodGroup ?? '-',
                  user.isActive ? 'Active' : 'Inactive',
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
