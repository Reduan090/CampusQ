import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('Signed in as'),
          subtitle: Text(auth.email ?? 'Unknown'),
          leading: const Icon(Icons.account_circle),
        ),
        const Divider(),
        const ListTile(
          title: Text('Firebase Integration (Free Tier)'),
          subtitle: Text('Use Firebase console and FlutterFire CLI to connect. This enables multi-user sync & push notifications.'),
          leading: Icon(Icons.cloud_outlined),
        ),
        const SizedBox(height: 8),
        const Text('Setup Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('1. flutter pub global activate flutterfire_cli'),
        const Text('2. dart pub global activate flutterfire_cli (if needed)'),
        const Text('3. flutterfire configure'),
        const Text('4. Add generated firebase_options.dart to lib/'),
        const Text('5. Switch AuthService to FirebaseAuth'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => context.read<AuthService>().signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
