// lib/screens/faculty/class_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/faculty_provider.dart';
import '../../models/class_profile.dart';
import '../../models/profiles/student_profile.dart';
import 'student_detail_screen.dart'; // Still navigating to student detail

class ClassDetailScreen extends StatefulWidget {
  final ClassProfile classProfile;
  const ClassDetailScreen({super.key, required this.classProfile});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FacultyProvider>(context, listen: false)
          .fetchStudentsForClass(widget.classProfile.classId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classProfile.className),
        backgroundColor: Colors.indigo,
      ),
      body: Consumer<FacultyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.studentsInSelectedClass.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }
          final students = provider.studentsInSelectedClass;
          if (students.isEmpty) {
            return const Center(child: Text("No students assigned to this class yet."));
          }

          // Sort students by risk status
          students.sort((a, b) {
            const ordering = {'High Risk': 0, 'Medium Risk': 1, 'Low Risk': 2};
            return (ordering[a.riskStatus] ?? 3).compareTo(ordering[b.riskStatus] ?? 3);
          });

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: student.riskColor,
                    child: Text(student.name[0], style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("ID: ${student.studentId} | Grade: ${student.latestGrade.toStringAsFixed(0)}%"), // Display grade
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(student.riskStatus, style: TextStyle(color: student.riskColor, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit_note), // Icon for editing grade
                        tooltip: 'Update Grade',
                        onPressed: () => _showUpdateGradeDialog(context, student), // Faculty can update grade
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to StudentDetailScreen as before (for viewing other details/sessions)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentDetailScreen(student: student),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Dialog for Faculty to update student's grade
  void _showUpdateGradeDialog(BuildContext context, StudentProfile student) {
    final gradeController = TextEditingController(text: student.latestGrade.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update Grade for ${student.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: gradeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'New Grade (%)'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a grade';
              }
              final grade = double.tryParse(value);
              if (grade == null || grade < 0 || grade > 100) {
                return 'Enter a valid grade between 0-100';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Update'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newGrade = double.parse(gradeController.text);
                if (newGrade != student.latestGrade) { // Only update if grade has changed
                  try {
                    await Provider.of<FacultyProvider>(context, listen: false).updateStudentGrade(student.studentId, newGrade);
                    Navigator.of(dialogContext).pop();
                  } on Exception catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                  }
                } else {
                  Navigator.of(dialogContext).pop(); // Close if no change
                }
              }
            },
          ),
        ],
      ),
    );
  }
}