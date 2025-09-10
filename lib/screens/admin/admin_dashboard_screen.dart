// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/profiles/student_profile.dart';
import '../../models/profiles/faculty_profile.dart';
import '../../models/profiles/counselor_profile.dart';
import '../../models/class_profile.dart';
import '../../services/api_service.dart'; // Make sure ApiService is imported for StudentCreate, etc.

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
    _tabController = TabController(length: 4, vsync: this);
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
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: "Students"),
            Tab(icon: Icon(Icons.person), text: "Faculty"),
            Tab(icon: Icon(Icons.support_agent), text: "Counselors"),
            Tab(icon: Icon(Icons.class_), text: "Classes"),
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
              _buildClassList(provider.classes, provider.faculty, provider.students),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleCreateButton(context),
        backgroundColor: Colors.indigo,
        tooltip: 'Create',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _handleCreateButton(BuildContext context) {
    switch (_tabController.index) {
      case 0: _showCreateStudentDialog(context); break;
      case 1: _showCreateFacultyDialog(context); break;
      case 2: _showCreateCounselorDialog(context); break;
      case 3: _showCreateClassDialog(context); break;
    }
  }

  // --- List View Widgets ---
  Widget _buildStudentList(List<StudentProfile> students) {
    if (students.isEmpty) return const Center(child: Text("No students created yet."));

    students.sort((a, b) {
      const ordering = {'High Risk': 0, 'Medium Risk': 1, 'Low Risk': 2};
      return (ordering[a.riskStatus] ?? 3).compareTo(ordering[b.riskStatus] ?? 3);
    });

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
            trailing: Row( // Use a Row for multiple trailing widgets if needed
              mainAxisSize: MainAxisSize.min, // Important to keep row compact
              children: [
                Text(student.riskStatus, style: TextStyle(color: student.riskColor, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.credit_card_off), // Icon for financial status
                  tooltip: 'Update Financial Status',
                  onPressed: () => _showUpdateFinancialStatusDialog(context, student), // Admin can update financial status
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFacultyList(List<FacultyProfile> faculty) {
    if (faculty.isEmpty) return const Center(child: Text("No faculty created yet."));
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
            trailing: Text(member.facultyId, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        );
      },
    );
  }

  Widget _buildCounselorList(List<CounselorProfile> counselors) {
    if (counselors.isEmpty) return const Center(child: Text("No counselors created yet."));
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
            trailing: Text(member.counselorId, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        );
      },
    );
  }

  Widget _buildClassList(List<ClassProfile> classes, List<FacultyProfile> allFaculty, List<StudentProfile> allStudents) {
    if (classes.isEmpty) return const Center(child: Text("No classes created yet."));
    return ListView.builder(
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classItem = classes[index];
        final facultyName = allFaculty.firstWhere((f) => f.facultyId == classItem.facultyId, orElse: () => FacultyProfile(facultyId: '', name: 'N/A', department: '')).name;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.class_outlined)),
            title: Text(classItem.className),
            subtitle: Text("Taught by: $facultyName | ${classItem.studentIds.length} students"),
            trailing: IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              tooltip: 'Assign Student',
              onPressed: () => _showAssignStudentDialog(context, classItem, allStudents),
            ),
          ),
        );
      },
    );
  }

  // --- Dialog Functions ---
  void _showCreateStudentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final controllers = {
      'name': TextEditingController(),
      'studentId': TextEditingController(),
      'username': TextEditingController(),
      'password': TextEditingController(),
      'attendance': TextEditingController(),
      'grade': TextEditingController()
    };
    String selectedFinancialStatus = 'Paid';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Student Record'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Create'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final data = StudentCreate(
                  name: controllers['name']!.text,
                  studentId: controllers['studentId']!.text,
                  username: controllers['username']!.text,
                  password: controllers['password']!.text,
                  initialAttendance: double.parse(controllers['attendance']!.text),
                  initialGrade: double.parse(controllers['grade']!.text),
                  financialStatus: selectedFinancialStatus,
                );
                try {
                  await ApiService().createStudent(data);
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: controllers['name'], decoration: const InputDecoration(labelText: 'Full Name')),
                TextFormField(controller: controllers['department'], decoration: const InputDecoration(labelText: 'Department')),
                TextFormField(controller: controllers['username'], decoration: const InputDecoration(labelText: 'Login Email')),
                TextFormField(controller: controllers['password'], decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Create'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final data = FacultyCreate(
                  name: controllers['name']!.text,
                  department: controllers['department']!.text,
                  username: controllers['username']!.text,
                  password: controllers['password']!.text,
                );
                try {
                  await ApiService().createFaculty(data);
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: controllers['name'], decoration: const InputDecoration(labelText: 'Full Name')),
                TextFormField(controller: controllers['specialization'], decoration: const InputDecoration(labelText: 'Specialization')),
                TextFormField(controller: controllers['username'], decoration: const InputDecoration(labelText: 'Login Email')),
                TextFormField(controller: controllers['password'], decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Create'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final data = CounselorCreate(
                  name: controllers['name']!.text,
                  specialization: controllers['specialization']!.text,
                  username: controllers['username']!.text,
                  password: controllers['password']!.text,
                );
                try {
                  await ApiService().createCounselor(data);
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

  void _showCreateClassDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final classNameController = TextEditingController();
    String? selectedFacultyId;
    final allFaculty = Provider.of<AdminProvider>(context, listen: false).faculty;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Class'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: classNameController, decoration: const InputDecoration(labelText: 'Class Name (e.g., CS 101)')),
              DropdownButtonFormField<String>(
                hint: const Text('Assign a Faculty Member'),
                value: selectedFacultyId,
                items: allFaculty.map((f) => DropdownMenuItem(value: f.facultyId, child: Text(f.name))).toList(),
                onChanged: (v) => selectedFacultyId = v,
                validator: (v) => v == null ? 'Faculty is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Create Class'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await ApiService().createClass(classNameController.text, selectedFacultyId!);
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

  void _showAssignStudentDialog(BuildContext context, ClassProfile classItem, List<StudentProfile> allStudents) {
    String? selectedStudentId;
    final availableStudents = allStudents.where((s) => !classItem.studentIds.contains(s.studentId)).toList();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Assign Student to ${classItem.className}'),
        content: DropdownButtonFormField<String>(
          hint: const Text('Select a Student'),
          value: selectedStudentId,
          items: availableStudents.map((s) => DropdownMenuItem(value: s.studentId, child: Text(s.name))).toList(),
          onChanged: (v) => selectedStudentId = v,
          validator: (v) => v == null ? 'Student is required' : null,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Assign'),
            onPressed: () async {
              if (selectedStudentId != null) {
                try {
                  await ApiService().assignStudentToClass(classItem.classId, selectedStudentId!);
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

  // Dialog for Admin to update student financial status
  void _showUpdateFinancialStatusDialog(BuildContext context, StudentProfile student) {
    String? selectedStatus = student.financialStatus;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update Financial Status for ${student.name}'),
        content: DropdownButtonFormField<String>(
          value: selectedStatus,
          items: ['Paid', 'Unpaid'].map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
          onChanged: (value) {
            selectedStatus = value;
          },
          decoration: const InputDecoration(labelText: 'Financial Status'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Update'),
            onPressed: () async {
              if (selectedStatus != null && selectedStatus != student.financialStatus) {
                try {
                  await Provider.of<AdminProvider>(context, listen: false).updateStudentFinancialStatus(student.studentId, selectedStatus!);
                  Navigator.of(dialogContext).pop();
                } on Exception catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              } else {
                Navigator.of(dialogContext).pop(); // Close if no change
              }
            },
          ),
        ],
      ),
    );
  }
}