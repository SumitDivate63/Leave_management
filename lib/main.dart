import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/faculty_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/leave_application_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/change_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LeaveManagementApp());
}

class LeaveManagementApp extends StatelessWidget {
  const LeaveManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Leave Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/student_dashboard': (context) => const StudentDashboard(),
        '/faculty_dashboard': (context) => const FacultyDashboard(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/leave_application': (context) => const LeaveApplicationScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/change_password': (context) => const ChangePasswordScreen(),
      },
    );
  }
}
