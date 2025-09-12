import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

class StudentQRScanner extends StatefulWidget {
  final String studentId; // Pass the student ID when navigating

  const StudentQRScanner({super.key, required this.studentId});

  @override
  State<StudentQRScanner> createState() => _StudentQRScannerState();
}

class _StudentQRScannerState extends State<StudentQRScanner> {
  String? scanResult;
  bool isSubmitting = false;
  bool hasScanned = false; // prevent multiple scans

  Future<void> submitAttendance(String qrString) async {
    setState(() {
      isSubmitting = true;
    });

    final url = Uri.parse("http://YOUR_API_URL/students/scan_qr/$qrString");

    try {
      final response = await http.post(url, body: {
        "student_id": widget.studentId,
      });

      if (response.statusCode == 200) {
        setState(() {
          scanResult = "✅ Attendance marked successfully!";
        });
      } else {
        setState(() {
          scanResult = "❌ Failed: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        scanResult = "⚠️ Error: $e";
      });
    }

    setState(() {
      isSubmitting = false;
    });
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
              onDetect: (barcodeCapture) {
                if (hasScanned) return; // avoid multiple triggers
                final barcode = barcodeCapture.barcodes.first;
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
