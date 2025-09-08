// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/student/student_dashboard_screen.dart';
import 'providers/admin_provider.dart';
import 'screens/faculty/faculty_dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const OblivionXApp(),
    ),
  );
}

class OblivionXApp extends StatelessWidget {
  const OblivionXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OblivionX',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.authState == AuthState.authenticated) {
          switch (authProvider.userRole) {
            case 'admin':
              return const AdminDashboardScreen();
            case 'student':
              return const StudentDashboardScreen();
            case 'faculty':
            case 'counselor':
              return const FacultyDashboardScreen();
            default:
              return const LoginScreen();
          }
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
