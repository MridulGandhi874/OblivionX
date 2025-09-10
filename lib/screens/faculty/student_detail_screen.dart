// lib/screens/faculty/student_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/profiles/student_profile.dart';
import '../../providers/student_provider.dart';
import '../../services/api_service.dart';
import '../../models/counseling_session.dart'; // Import CounselingSession to use SessionStatus enum
import 'package:intl/intl.dart';

class StudentDetailScreen extends StatefulWidget {
  final StudentProfile student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // StudentProvider now needs a method to fetch sessions specifically for the current student
      // Assuming StudentProvider has a fetchSessionsForStudent that calls ApiService().getSessionsForStudent
      Provider.of<StudentProvider>(context, listen: false)
          .fetchSessionsForStudent(widget.student.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.name),
        backgroundColor: Colors.indigo,
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.sessions.isEmpty) { // Check if loading and no existing data
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }
          return RefreshIndicator(
            onRefresh: () =>
                provider.fetchSessionsForStudent(widget.student.studentId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStudentSummaryCard(widget.student),
                const SizedBox(height: 24),
                _buildSessionHistory(provider.sessions),
              ],
            ),
          );
        },
      ),
      // Only counselors should initiate/update sessions, not faculty in this shared screen.
      // Removing FAB or making it conditionally visible based on role.
      // For now, let's assume this screen is only for viewing by faculty.
      // If a FAB is needed for faculty to "request" a session, that's different logic.
      // FloatingActionButton(
      //   onPressed: () => _showCreateOrUpdateSessionDialog(
      //       context, widget.student.studentId),
      //   backgroundColor: Colors.indigo,
      //   tooltip: 'Initiate New Session',
      //   child: const Icon(Icons.add_comment_outlined),
      // ),
    );
  }

  Widget _buildStudentSummaryCard(StudentProfile student) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Student Profile",
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20),
            _buildInfoRow("ID", student.studentId),
            _buildInfoRow("Risk Status", student.riskStatus,
                color: student.riskColor),
            _buildInfoRow("Attendance", "${student.attendancePercentage.toStringAsFixed(0)}%"),
            _buildInfoRow("Latest Grade", "${student.latestGrade.toStringAsFixed(0)}%"),
            _buildInfoRow("Financials", student.financialStatus,
                color: student.financialStatus == 'Unpaid'
                    ? Colors.red
                    : Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color ?? Colors.black)),
        ],
      ),
    );
  }

  Widget _buildSessionHistory(List<CounselingSession> sessions) {
    // Sort sessions by date, newest first
    sessions.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Counseling History",
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20),
            if (sessions.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No counseling sessions found."))),
            ...sessions.map((session) => ListTile(
              leading: Icon(
                // ✅ Corrected: Compare with enum value
                session.status == SessionStatus.open
                    ? Icons.chat_bubble_outline
                    : Icons.check_circle_outline,
                // ✅ Corrected: Use enum extension for color
                color: session.status.statusColor,
              ),
              title: Text(DateFormat.yMMMd()
                  .add_jm()
                  .format(session.sessionDate.toLocal())),
              subtitle: Text(session.notes,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              // ✅ Corrected: Use enum.name for display
              trailing: Text(session.status.name),
              // Faculty should not be able to tap to update/create sessions here.
              // This is a view-only screen for faculty regarding counseling.
              // If a faculty needs to request a session, it should be a dedicated button, not tapping existing sessions.
              onTap: () {
                // You could optionally show a read-only dialog of the session details here
                _showSessionDetailsDialog(context, session);
              },
            )),
          ],
        ),
      ),
    );
  }

  // New method to show read-only session details for faculty
  void _showSessionDetailsDialog(BuildContext context, CounselingSession session) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Counseling Session Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Date: ${DateFormat.yMMMd().add_jm().format(session.sessionDate.toLocal())}'),
                const SizedBox(height: 8),
                Text('Status: ${session.status.name}', style: TextStyle(color: session.status.statusColor)),
                const SizedBox(height: 8),
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(session.notes),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

// Removed _showCreateOrUpdateSessionDialog from faculty student_detail_screen.
// This functionality belongs only to the CounselorStudentDetailScreen.
// Faculty only *view* counseling sessions, they do not initiate or update them.
}