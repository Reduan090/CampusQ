import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoApproveEnabled = false;
  int _maxQueueSize = 50;
  int _tokenValidityDays = 7;
  String _selectedTheme = 'System';
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Account section
        Text(
          'Account',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.admin_panel_settings),
            ),
            title: Text(auth.email ?? 'Not signed in'),
            subtitle: const Text('Administrator Account'),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Notification settings
        Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive alerts for new token requests'),
                value: _notificationsEnabled,
                onChanged: (value) => setState(() => _notificationsEnabled = value),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Auto-Approve Tokens'),
                subtitle: const Text('Automatically approve all token requests'),
                value: _autoApproveEnabled,
                onChanged: (value) => setState(() => _autoApproveEnabled = value),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Queue settings
        Text(
          'Queue Management',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Maximum Queue Size'),
                subtitle: Text('Current limit: $_maxQueueSize tokens'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _maxQueueSize > 10
                          ? () => setState(() => _maxQueueSize -= 5)
                          : null,
                    ),
                    Text('$_maxQueueSize'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _maxQueueSize < 200
                          ? () => setState(() => _maxQueueSize += 5)
                          : null,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Default Token Validity'),
                subtitle: Text('Tokens expire after $_tokenValidityDays days'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _tokenValidityDays > 1
                          ? () => setState(() => _tokenValidityDays--)
                          : null,
                    ),
                    Text('$_tokenValidityDays'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _tokenValidityDays < 30
                          ? () => setState(() => _tokenValidityDays++)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Appearance settings
        Text(
          'Appearance',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Theme'),
                trailing: DropdownButton<String>(
                  value: _selectedTheme,
                  items: const [
                    DropdownMenuItem(value: 'Light', child: Text('Light')),
                    DropdownMenuItem(value: 'Dark', child: Text('Dark')),
                    DropdownMenuItem(value: 'System', child: Text('System')),
                  ],
                  onChanged: (value) => setState(() => _selectedTheme = value!),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                trailing: DropdownButton<String>(
                  value: _selectedLanguage,
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Bengali', child: Text('Bengali')),
                    DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                  ],
                  onChanged: (value) => setState(() => _selectedLanguage = value!),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Data management
        Text(
          'Data Management',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export Data'),
                subtitle: const Text('Download all data as JSON'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export functionality coming soon')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('Import Data'),
                subtitle: const Text('Import data from JSON file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Import functionality coming soon')),
                  );
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Sign out
        Card(
          color: Colors.red.shade50,
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade700),
            title: Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text('Sign out from admin account'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        auth.signOut();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 24),
        
        // App version
        Center(
          child: Text(
            'HCI Token Management System v1.0.0',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Colors.grey,
                ),
          ),
        ),
      ],
    );
  }
}
