// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/student_model.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
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
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.indigo,
        actions: [
          // --- THIS IS THE LOGOUT BUTTON ---
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Clear data from providers before navigating away
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateUserDialog(context),
        backgroundColor: Colors.indigo,
        tooltip: 'Create New User',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildBody(StudentProvider provider) {
    // (This buildBody function remains the same as before)
    if (provider.isLoading && provider.students.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return Center(child: Text("Error: ${provider.errorMessage}"));
    }
    if (provider.students.isEmpty) {
      return const Center(child: Text("No student data available."));
    }
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
                  child: Text(student.name[0], style: const TextStyle(color: Colors.white))),
              title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("ID: ${student.studentId}"),
              trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: student.riskColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(student.riskStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        );
      },
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'student';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Use a different context name
        return AlertDialog(
          title: const Text('Create New User'),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username (Email)'),
                  validator: (value) => value!.isEmpty ? 'Cannot be empty' : null),
              TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? 'Cannot be empty' : null),
              DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: ['student', 'faculty', 'counselor']
                      .map((String value) => DropdownMenuItem<String>(
                      value: value, child: Text(value.toUpperCase())))
                      .toList(),
                  onChanged: (newValue) => selectedRole = newValue!,
                  decoration: const InputDecoration(labelText: 'Role'))
            ]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final apiService = ApiService();
                  try {
                    await apiService.createUser(
                      usernameController.text,
                      passwordController.text,
                      selectedRole,
                    );
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('User created successfully!'),
                        backgroundColor: Colors.green));

                    // --- THIS IS THE AUTO-REFRESH FIX ---
                    Provider.of<StudentProvider>(context, listen: false).fetchAllStudents();

                  } on Exception catch (e) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
                        backgroundColor: Colors.red));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}