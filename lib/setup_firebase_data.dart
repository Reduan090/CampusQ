import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

/// Run this script to set up initial Firebase data
/// Usage: dart run lib/setup_firebase_data.dart
void main() async {
  print('🚀 Starting Firebase setup...\n');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized\n');

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // Step 1: Create Admin User
    print('👤 Creating admin user...');
    UserCredential? adminCred;
    try {
      adminCred = await auth.createUserWithEmailAndPassword(
        email: 'admin@campusq.com',
        password: 'admin123',
      );
      print('✅ Admin account created: admin@campusq.com / admin123');
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        print('ℹ️  Admin account already exists, signing in...');
        adminCred = await auth.signInWithEmailAndPassword(
          email: 'admin@campusq.com',
          password: 'admin123',
        );
      } else {
        print('❌ Error creating admin: $e');
        rethrow;
      }
    }

    // Step 2: Create Admin User Document
    if (adminCred != null) {
      await firestore.collection('users').doc(adminCred.user!.uid).set({
        'uid': adminCred.user!.uid,
        'email': 'admin@campusq.com',
        'role': 'admin',
        'isActive': true,
        'name': 'System Administrator',
        'studentId': 'ADMIN001',
        'department': 'IT Department',
        'bloodGroup': 'O+',
        'pictureUrl': null,
        'createdAt': DateTime.now().toIso8601String(),
      });
      print('✅ Admin user document created\n');
    }

    // Step 3: Create Sample Student Users
    print('👥 Creating sample student users...');
    
    final students = [
      {
        'email': 'john.doe@student.campusq.com',
        'password': 'student123',
        'name': 'John Doe',
        'studentId': 'CSE2021001',
        'department': 'Computer Science',
        'bloodGroup': 'A+',
      },
      {
        'email': 'jane.smith@student.campusq.com',
        'password': 'student123',
        'name': 'Jane Smith',
        'studentId': 'EEE2021002',
        'department': 'Electrical Engineering',
        'bloodGroup': 'B+',
      },
      {
        'email': 'mike.johnson@student.campusq.com',
        'password': 'student123',
        'name': 'Mike Johnson',
        'studentId': 'ME2021003',
        'department': 'Mechanical Engineering',
        'bloodGroup': 'O-',
      },
      {
        'email': 'sarah.williams@student.campusq.com',
        'password': 'student123',
        'name': 'Sarah Williams',
        'studentId': 'BBA2021004',
        'department': 'Business Administration',
        'bloodGroup': 'AB+',
      },
      {
        'email': 'david.brown@student.campusq.com',
        'password': 'student123',
        'name': 'David Brown',
        'studentId': 'CSE2021005',
        'department': 'Computer Science',
        'bloodGroup': 'A-',
      },
    ];

    for (var student in students) {
      try {
        final userCred = await auth.createUserWithEmailAndPassword(
          email: student['email'] as String,
          password: student['password'] as String,
        );

        await firestore.collection('users').doc(userCred.user!.uid).set({
          'uid': userCred.user!.uid,
          'email': student['email'],
          'role': 'student',
          'isActive': true,
          'name': student['name'],
          'studentId': student['studentId'],
          'department': student['department'],
          'bloodGroup': student['bloodGroup'],
          'pictureUrl': null,
          'createdAt': DateTime.now().toIso8601String(),
        });

        print('✅ Created: ${student['name']} (${student['email']})');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('ℹ️  User already exists: ${student['email']}');
        } else {
          print('❌ Error creating ${student['name']}: $e');
        }
      }
    }
    print('');

    // Step 4: Create Sample Notices
    print('📢 Creating sample notices...');
    
    final notices = [
      {
        'title': 'Welcome to CampusQ!',
        'content': 'Welcome to the new Virtual Token System. Request tokens for various campus services easily and track your queue position in real-time.',
        'isActive': true,
      },
      {
        'title': 'System Maintenance Schedule',
        'content': 'The cafeteria token system will be under maintenance on December 15, 2025 from 2 PM to 4 PM. Please plan accordingly.',
        'isActive': true,
      },
      {
        'title': 'New Feature: Profile Management',
        'content': 'Students can now update their profile information including name, department, blood group, and profile picture from the Profile tab.',
        'isActive': true,
      },
      {
        'title': 'Token Request Guidelines',
        'content': 'Please add a clear message when requesting tokens to help administrators process your request faster. Approved tokens will be notified via the system.',
        'isActive': true,
      },
      {
        'title': 'Holiday Notice',
        'content': 'The campus will be closed on December 25, 2025 for Christmas. No token services will be available on this day.',
        'isActive': false,
      },
    ];

    for (var notice in notices) {
      final docRef = await firestore.collection('notices').add({
        'title': notice['title'],
        'content': notice['content'],
        'isActive': notice['isActive'],
        'createdBy': adminCred!.user!.uid,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // Update with the document ID
      await docRef.update({'id': docRef.id});
      print('✅ Notice created: ${notice['title']}');
    }
    print('');

    // Step 5: Create Sample Tokens
    print('🎫 Creating sample tokens...');
    
    // Get one student user for sample tokens
    final usersSnapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .limit(2)
        .get();

    if (usersSnapshot.docs.isNotEmpty) {
      final tokenTypes = ['cafeteria', 'library', 'transport', 'counseling'];
      final statuses = ['pending', 'approved', 'waiting', 'completed'];
      
      int tokenCounter = 1;
      
      for (int i = 0; i < usersSnapshot.docs.length; i++) {
        final studentDoc = usersSnapshot.docs[i];
        
        for (int j = 0; j < 2; j++) {
          final type = tokenTypes[j % tokenTypes.length];
          final status = statuses[j % statuses.length];
          final now = DateTime.now();
          final requestTime = now.subtract(Duration(hours: j + 1));
          
          final tokenDoc = await firestore.collection('tokens').add({
            'userId': studentDoc.id,
            'type': type,
            'status': status,
            'queuePosition': j + 1,
            'totalInQueue': 5,
            'requestedAt': requestTime.toIso8601String(),
            'message': j == 0 ? 'Need urgent assistance' : null,
            'completedAt': status == 'completed' ? now.toIso8601String() : null,
          });
          
          // Update with token number and id
          await tokenDoc.update({
            'id': tokenDoc.id,
            'tokenNumber': 'T${tokenCounter.toString().padLeft(3, '0')}',
          });
          
          print('✅ Token created: T${tokenCounter.toString().padLeft(3, '0')} - $type ($status)');
          tokenCounter++;
        }
      }
    }
    print('');

    // Summary
    print('═══════════════════════════════════════════════');
    print('✨ Firebase Setup Complete! ✨');
    print('═══════════════════════════════════════════════\n');
    
    print('👤 ADMIN LOGIN:');
    print('   Email: admin@campusq.com');
    print('   Password: admin123\n');
    
    print('👥 SAMPLE STUDENT LOGINS:');
    for (var student in students) {
      print('   ${student['name']}:');
      print('   Email: ${student['email']}');
      print('   Password: ${student['password']}\n');
    }
    
    print('📊 DATA CREATED:');
    print('   • 1 Admin user');
    print('   • ${students.length} Student users');
    print('   • ${notices.length} Notices');
    print('   • Sample tokens\n');
    
    print('🔗 Firebase Console:');
    print('   https://console.firebase.google.com/project/campusq-d754c\n');
    
    print('✅ You can now run the app and sign in with any of the above credentials!');
    print('');

  } catch (e) {
    print('❌ Setup failed: $e');
    print('\nPlease ensure:');
    print('1. Firebase Authentication is enabled');
    print('2. Firestore Database is created');
    print('3. Security rules are set up');
    print('4. You have internet connection');
  }
}
