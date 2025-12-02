import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/classic_theme.dart';
import 'services/token_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/notice_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TokenService(),
        ),
        ProxyProvider<TokenService, NotificationService>(
          update: (_, tokenService, __) => NotificationService(tokenService),
          dispose: (_, notificationService) => notificationService.dispose(),
        ),
        ChangeNotifierProvider(create: (_) => AuthService()..initialize()),
      ],
      child: MaterialApp(
        title: 'Virtual Token System',
        debugShowCheckedModeBanner: false,
        theme: ClassicTheme.light(),
        home: const _Bootstrap(),
      ),
    );
  }
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  bool _firebaseReady = false;
  String? _firebaseError;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      setState(() => _firebaseReady = true);
    } catch (e) {
      // Firebase is required for this app
      setState(() => _firebaseError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_firebaseError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Connection Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _firebaseError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _firebaseError = null;
                      _firebaseReady = false;
                    });
                    _initFirebase();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (!_firebaseReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return MultiProvider(
      providers: [
        // Replace TokenService with Firestore-backed instance when Firebase is ready
        ChangeNotifierProvider(
          create: (_) => TokenService(
            useFirestore: _firebaseReady,
            firestore: _firebaseReady ? FirebaseFirestore.instance : null,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UserService(
            firestore: _firebaseReady ? FirebaseFirestore.instance : null,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NoticeService(
            firestore: _firebaseReady ? FirebaseFirestore.instance : null,
          ),
        ),
      ],
      child: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    // Wait for prefs
    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // Reinitialize TokenService listener when user logs in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<TokenService>().reinitializeListener();
      } catch (e) {
        // Service might not be available yet
      }
    });

    return auth.role == UserRole.admin ? const AdminHomeScreen() : const HomeScreen();
  }
}
