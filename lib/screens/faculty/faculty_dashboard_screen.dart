// lib/screens/faculty/faculty_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/faculty_provider.dart';
import 'class_detail_screen.dart'; // Import the new detail screen

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch the classes assigned to this faculty member
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FacultyProvider>(context, listen: false).fetchMyClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final facultyProvider = Provider.of<FacultyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Classes"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              facultyProvider.clearData();
              authProvider.logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => facultyProvider.fetchMyClasses(),
        child: _buildBody(facultyProvider),
      ),
    );
  }

  Widget _buildBody(FacultyProvider provider) {
    if (provider.isLoading && provider.classes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(child: Text("Error: ${provider.errorMessage}"));
    }
    if (provider.classes.isEmpty) {
      return const Center(
        child: Text("You have not been assigned to any classes."),
      );
    }

    return ListView.builder(
      itemCount: provider.classes.length,
      itemBuilder: (context, index) {
        final classProfile = provider.classes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.class_outlined, color: Colors.white),
            ),
            title: Text(classProfile.className, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${classProfile.studentIds.length} students enrolled"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to the ClassDetailScreen with the selected class
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassDetailScreen(classProfile: classProfile),
                ),
              );
            },
          ),
        );
      },
    );
  }
}