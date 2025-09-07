// lib/screens/faculty/faculty_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/student_model.dart';

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch all student data when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchAllStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Faculty & Counselor Dashboard"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              studentProvider.clearData();
              authProvider.logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => studentProvider.fetchAllStudents(),
        child: _buildBody(studentProvider),
      ),
    );
  }

  Widget _buildBody(StudentProvider provider) {
    if (provider.isLoading && provider.students.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(child: Text("Error: ${provider.errorMessage}"));
    }

    if (provider.students.isEmpty) {
      return const Center(
        child: Text("No student data available."),
      );
    }

    // Sort students to show High Risk first
    List<Student> sortedStudents = List.from(provider.students);
    sortedStudents.sort((a, b) {
      const ordering = {'High Risk': 0, 'Medium Risk': 1, 'Low Risk': 2};
      return (ordering[a.riskStatus] ?? 3).compareTo(ordering[b.riskStatus] ?? 3);
    });

    return ListView.builder(
      itemCount: sortedStudents.length,
      itemBuilder: (context, index) {
        final student = sortedStudents[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: student.riskColor,
              child: Text(student.name[0], style: const TextStyle(color: Colors.white)),
            ),
            title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("ID: ${student.studentId} | Attendance: ${student.attendancePercentage.toStringAsFixed(1)}%"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: student.riskColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                student.riskStatus,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}