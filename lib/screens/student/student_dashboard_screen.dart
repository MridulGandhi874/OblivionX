// lib/screens/student/student_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // ✅ replaced qr_code_scanner
import 'package:http/http.dart' as http;

import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/profiles/student_profile.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchMyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final StudentProfile? student = studentProvider.currentStudent;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Dashboard"),
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
        onRefresh: () => studentProvider.fetchMyData(),
        child: Center(
          child: _buildBody(studentProvider, student),
        ),
      ),
    );
  }

  Widget _buildBody(StudentProvider provider, StudentProfile? student) {
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
        const SizedBox(height: 24),
        _buildQRButton(student),
      ],
    );
  }

  Widget _buildHeader(StudentProfile student) {
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
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
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
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(StudentProfile student) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Academic Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.attach_money,
              label: "Financial Status",
              value: student.financialStatus,
              color: student.financialStatus == 'Paid'
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      {required IconData icon,
        required String label,
        required String value,
        required Color color}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
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
            const Text("Personalized Guidance",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            ListTile(
              leading:
              Icon(Icons.lightbulb_outline, color: Colors.amber.shade800),
              title: const Text("Task for your free period"),
              subtitle: const Text("Review notes for 'Advanced Algorithms'."),
            ),
            ListTile(
              leading:
              Icon(Icons.calendar_today_outlined, color: Colors.teal.shade700),
              title: const Text("Upcoming Schedule"),
              subtitle: const Text("Class: Data Structures at 10:00 AM."),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRButton(StudentProfile student) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
      label: const Text(
        "Scan Attendance QR",
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QRScannerPage(studentId: student.studentId),
          ),
        );
      },
    );
  }
}

// 🔹 Student QR Scanner Page using mobile_scanner
class QRScannerPage extends StatefulWidget {
  final String studentId;
  const QRScannerPage({super.key, required this.studentId});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  String? scanResult;
  bool isSubmitting = false;
  bool hasScanned = false;

  Future<void> submitAttendance(String qrString) async {
    setState(() => isSubmitting = true);

    final url = Uri.parse("http://10.106.55.237:8000/students/scan_qr/$qrString");

    try {
      final response =
      await http.post(url, body: {"student_id": widget.studentId});

      if (response.statusCode == 200) {
        setState(() => scanResult = "✅ Attendance marked!");
      } else {
        setState(() => scanResult = "❌ Failed: ${response.body}");
      }
    } catch (e) {
      setState(() => scanResult = "⚠️ Error: $e");
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Attendance QR")),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              onDetect: (capture) {
                if (hasScanned) return;
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null) {
                  setState(() {
                    scanResult = barcode.rawValue;
                    hasScanned = true;
                  });
                  submitAttendance(barcode.rawValue!);
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: isSubmitting
                  ? const CircularProgressIndicator()
                  : Text(scanResult ?? "Scan a QR code"),
            ),
          ),
        ],
      ),
    );
  }
}
