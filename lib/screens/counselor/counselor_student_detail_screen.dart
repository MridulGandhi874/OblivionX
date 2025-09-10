// lib/screens/counselor/counselor_student_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/profiles/student_profile.dart';
import '../../models/counseling_session.dart'; // Import CounselingSession which now defines SessionStatus
import '../../providers/counselor_provider.dart';

class CounselorStudentDetailScreen extends StatefulWidget {
  final StudentProfile student;
  const CounselorStudentDetailScreen({super.key, required this.student});

  @override
  State<CounselorStudentDetailScreen> createState() => _CounselorStudentDetailScreenState();
}

class _CounselorStudentDetailScreenState extends State<CounselorStudentDetailScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    // Ensure this runs after the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CounselorProvider>(context, listen: false)
          .fetchSessionsForStudent(widget.student.studentId);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.name),
        backgroundColor: Colors.teal, // Counselor-specific color
      ),
      body: Consumer<CounselorProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.studentSessions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text("Error: ${provider.errorMessage}"));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStudentInfoCard(widget.student),
                  const SizedBox(height: 20),
                  _buildCreateSessionCard(context, provider),
                  const SizedBox(height: 20),
                  _buildSessionHistory(provider.studentSessions, provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentInfoCard(StudentProfile student) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student ID: ${student.studentId}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Grade: ${student.latestGrade.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Attendance: ${student.attendancePercentage.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Financial Status: ${student.financialStatus}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Risk Status: ', style: TextStyle(fontSize: 16)),
                Text(
                  student.riskStatus,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: student.riskColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateSessionCard(BuildContext context, CounselorProvider provider) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create New Counseling Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Session Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: provider.isLoading ? null : () async {
                if (_notesController.text.isNotEmpty) {
                  await provider.createSession(widget.student.studentId, _notesController.text);
                  _notesController.clear(); // Clear input after creating
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notes cannot be empty.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: provider.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHistory(List<CounselingSession> sessions, CounselorProvider provider) {
    if (sessions.isEmpty) {
      return const Center(child: Text("No counseling sessions for this student."));
    }

    // Sort sessions by date, newest first
    sessions.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Session History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session on: ${session.sessionDate.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Status: ${session.status.name}', style: TextStyle(color: session.status.statusColor)),
                    const SizedBox(height: 5),
                    Text('Notes: ${session.notes}'),
                    const SizedBox(height: 10),
                    if (session.status == SessionStatus.open) // Allow editing only if session is open
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () => _showEditSessionDialog(context, session, provider),
                          child: const Text('Edit Session'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showEditSessionDialog(BuildContext context, CounselingSession session, CounselorProvider provider) {
    final TextEditingController editNotesController = TextEditingController(text: session.notes);
    String editSelectedStatusString = session.status.name; // Initial value from existing session (as String)

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Counseling Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: editNotesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: editSelectedStatusString, // Use the string value
              decoration: const InputDecoration(labelText: 'Status'),
              items: SessionStatus.values.map((status) {
                return DropdownMenuItem<String>( // Explicitly define type as String
                  value: status.name, // The value should be the enum's name string
                  child: Text(status.name),
                );
              }).toList(),
              onChanged: (value) {
                editSelectedStatusString = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: provider.isLoading ? null : () async {
              if (editNotesController.text.isNotEmpty) {
                await provider.updateSession(
                  session.sessionId,
                  editNotesController.text,
                  editSelectedStatusString, // Pass the string directly
                  widget.student.studentId, // Pass studentId to re-fetch sessions
                );
                Navigator.of(dialogContext).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notes cannot be empty.')),
                );
              }
            },
            child: provider.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Update'),
          ),
        ],
      ),
    );
  }
}