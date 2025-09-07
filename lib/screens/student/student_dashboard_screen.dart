// lib/screens/student/student_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/student_model.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to fetch data after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchMyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final Student? student = studentProvider.currentStudent;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Dashboard"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Clear student data before logging out
              studentProvider.clearData();
              authProvider.logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => studentProvider.fetchMyData(),
        child: Center(
          child: _buildBody(studentProvider, student),
        ),
      ),
    );
  }

  Widget _buildBody(StudentProvider provider, Student? student) {
    if (provider.isLoading) {
      return const CircularProgressIndicator();
    }

    if (provider.errorMessage != null) {
      return Text("Error: ${provider.errorMessage}");
    }

    if (student == null) {
      return const Text("No personal data found.");
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildHeader(student),
        const SizedBox(height: 24),
        _buildInfoCard(student),
        const SizedBox(height: 24),
        _buildPersonalizedGuidance(),
      ],
    );
  }

  Widget _buildHeader(Student student) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: student.riskColor.withOpacity(0.2),
          child: Text(
            student.name[0],
            style: TextStyle(fontSize: 48, color: student.riskColor),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Welcome, ${student.name}",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: student.riskColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Current Status: ${student.riskStatus}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Student student) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Academic Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.pie_chart,
              label: "Attendance",
              value: "${student.attendancePercentage.toStringAsFixed(1)}%",
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.school,
              label: "Latest Grade",
              value: "${student.latestGrade.toStringAsFixed(1)} / 100",
              color: Colors.purple.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value, required Color color}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPersonalizedGuidance() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Personalized Guidance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            ListTile(
              leading: Icon(Icons.lightbulb_outline, color: Colors.amber.shade800),
              title: const Text("Task for your free period"),
              subtitle: const Text("Review notes for 'Advanced Algorithms' - Chapter 3."),
            ),
            ListTile(
              leading: Icon(Icons.calendar_today_outlined, color: Colors.teal.shade700),
              title: const Text("Upcoming Schedule"),
              subtitle: const Text("Class: Data Structures at 10:00 AM."),
            ),
          ],
        ),
      ),
    );
  }
}