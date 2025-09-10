// lib/screens/counselor/counselor_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/counselor_provider.dart';
import '../../models/profiles/student_profile.dart';
// ✅ Corrected: Import the new counselor-specific student detail screen
import 'counselor_student_detail_screen.dart';

class CounselorDashboardScreen extends StatefulWidget {
  const CounselorDashboardScreen({super.key});

  @override
  State<CounselorDashboardScreen> createState() => _CounselorDashboardScreenState();
}

class _CounselorDashboardScreenState extends State<CounselorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CounselorProvider>(context, listen: false).fetchAllStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final counselorProvider = Provider.of<CounselorProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Counselor's Intervention Panel"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              counselorProvider.clearData();
              authProvider.logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => counselorProvider.fetchAllStudents(),
        child: _buildBody(counselorProvider),
      ),
    );
  }

  Widget _buildBody(CounselorProvider provider) {
    if (provider.isLoading && provider.allStudents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(child: Text("Error: ${provider.errorMessage}"));
    }
    if (provider.allStudents.isEmpty) {
      return const Center(child: Text("No student data available for counseling."));
    }

    List<StudentProfile> sortedStudents = List.from(provider.allStudents);
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
            subtitle: Text("ID: ${student.studentId}"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // ✅ Corrected: Navigate to CounselorStudentDetailScreen
                  builder: (context) => CounselorStudentDetailScreen(student: student),
                ),
              );
            },
          ),
        );
      },
    );
  }
}