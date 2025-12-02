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
      // If options not configured yet, continue app without Firebase
      setState(() => _firebaseError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_firebaseReady && _firebaseError == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return MultiProvider(
      providers: [
        // Replace TokenService with Firestore-backed instance when Firebase is ready
        ChangeNotifierProvider(
          create: (_) => TokenService(
            useFirestore: _firebaseReady,
            firestore: _firebaseReady ? FirebaseFirestore.instance : null,
            userId: FirebaseAuth.instance.currentUser?.uid,
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

    return auth.role == UserRole.admin ? const AdminHomeScreen() : const HomeScreen();
  }
}
