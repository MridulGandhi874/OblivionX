// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/profiles/student_profile.dart';
import '../../models/profiles/faculty_profile.dart';
import '../../models/profiles/counselor_profile.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Control Panel"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AdminProvider>(context, listen: false).clearAllData();
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: "Students"),
            Tab(icon: Icon(Icons.person), text: "Faculty"),
            Tab(icon: Icon(Icons.support_agent), text: "Counselors"),
          ],
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildStudentList(provider.students),
              _buildFacultyList(provider.faculty),
              _buildCounselorList(provider.counselors),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleCreateButton(context),
        backgroundColor: Colors.indigo,
        tooltip: 'Create New User',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _handleCreateButton(BuildContext context) {
    switch (_tabController.index) {
      case 0: _showCreateStudentDialog(context); break;
      case 1: _showCreateFacultyDialog(context); break;
      case 2: _showCreateCounselorDialog(context); break;
    }
  }

  // --- List View Widgets ---
  Widget _buildStudentList(List<StudentProfile> students) {
    if (students.isEmpty) return const Center(child: Text("No students found."));
    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: student.riskColor, child: Text(student.name[0])),
            title: Text(student.name),
            subtitle: Text("ID: ${student.studentId} | Status: ${student.financialStatus}"),
            trailing: Text(student.riskStatus, style: TextStyle(color: student.riskColor, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildFacultyList(List<FacultyProfile> faculty) {
    if (faculty.isEmpty) return const Center(child: Text("No faculty found."));
    return ListView.builder(
      itemCount: faculty.length,
      itemBuilder: (context, index) {
        final member = faculty[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(member.name),
            subtitle: Text("Department: ${member.department}"),
          ),
        );
      },
    );
  }

  Widget _buildCounselorList(List<CounselorProfile> counselors) {
    if (counselors.isEmpty) return const Center(child: Text("No counselors found."));
    return ListView.builder(
      itemCount: counselors.length,
      itemBuilder: (context, index) {
        final member = counselors[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.support_agent_outlined)),
            title: Text(member.name),
            subtitle: Text("Specialization: ${member.specialization}"),
          ),
        );
      },
    );
  }

  // --- Dialog Functions with Corrected Refresh Logic ---

  void _showCreateStudentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final controllers = {
      'name': TextEditingController(), 'studentId': TextEditingController(),
      'username': TextEditingController(), 'password': TextEditingController(),
      'attendance': TextEditingController(), 'grade': TextEditingController(),
    };
    String selectedFinancialStatus = 'Paid';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Student Record'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: controllers['name'], decoration: const InputDecoration(labelText: 'Full Name')),
            TextFormField(controller: controllers['studentId'], decoration: const InputDecoration(labelText: 'Official Student ID')),
            TextFormField(controller: controllers['username'], decoration: const InputDecoration(labelText: 'Login Email')),
            TextFormField(controller: controllers['password'], decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            TextFormField(controller: controllers['attendance'], decoration: const InputDecoration(labelText: 'Initial Attendance %'), keyboardType: TextInputType.number),
            TextFormField(controller: controllers['grade'], decoration: const InputDecoration(labelText: 'Initial Grade %'), keyboardType: TextInputType.number),
            DropdownButtonFormField<String>(
              value: selectedFinancialStatus,
              items: ['Paid', 'Unpaid'].map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
              onChanged: (v) => selectedFinancialStatus = v!,
              decoration: const InputDecoration(labelText: 'Financial Status'),
            ),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Create'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final data = StudentCreate(
                  name: controllers['name']!.text, studentId: controllers['studentId']!.text,
                  username: controllers['username']!.text, password: controllers['password']!.text,
                  initialAttendance: double.parse(controllers['attendance']!.text),
                  initialGrade: double.parse(controllers['grade']!.text),
                  financialStatus: selectedFinancialStatus,
                );
                try {
                  await ApiService().createStudent(data);
                  // ✅ FIXED: Refresh data BEFORE closing the dialog
                  await Provider.of<AdminProvider>(context, listen: false).fetchAllData();
                  Navigator.of(dialogContext).pop();
                } on Exception catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCreateFacultyDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final controllers = {'name': TextEditingController(), 'department': TextEditingController(), 'username': TextEditingController(), 'password': TextEditingController()};

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Faculty'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: controllers['name'], decoration: const InputDecoration(labelText: 'Full Name')),
            TextFormField(controller: controllers['department'], decoration: const InputDecoration(labelText: 'Department')),
            TextFormField(controller: controllers['username'], decoration: const InputDecoration(labelText: 'Login Email')),
            TextFormField(controller: controllers['password'], decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Create'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final data = FacultyCreate(
                  name: controllers['name']!.text, department: controllers['department']!.text,
                  username: controllers['username']!.text, password: controllers['password']!.text,
                );
                try {
                  await ApiService().createFaculty(data);
                  // ✅ FIXED: Refresh data BEFORE closing the dialog
                  await Provider.of<AdminProvider>(context, listen: false).fetchAllData();
                  Navigator.of(dialogContext).pop();
                } on Exception catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCreateCounselorDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final controllers = {'name': TextEditingController(), 'specialization': TextEditingController(), 'username': TextEditingController(), 'password': TextEditingController()};

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Counselor'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: controllers['name'], decoration: const InputDecoration(labelText: 'Full Name')),
            TextFormField(controller: controllers['specialization'], decoration: const InputDecoration(labelText: 'Specialization')),
            TextFormField(controller: controllers['username'], decoration: const InputDecoration(labelText: 'Login Email')),
            TextFormField(controller: controllers['password'], decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Create'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final data = CounselorCreate(
                  name: controllers['name']!.text, specialization: controllers['specialization']!.text,
                  username: controllers['username']!.text, password: controllers['password']!.text,
                );
                try {
                  await ApiService().createCounselor(data);
                  // ✅ FIXED: Refresh data BEFORE closing the dialog
                  await Provider.of<AdminProvider>(context, listen: false).fetchAllData();
                  Navigator.of(dialogContext).pop();
                } on Exception catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}