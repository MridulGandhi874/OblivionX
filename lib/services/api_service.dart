// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/profiles/student_profile.dart';
import '../models/profiles/faculty_profile.dart';
import '../models/profiles/counselor_profile.dart';
import 'secure_storage_service.dart';

class ApiService {
  final SecureStorageService _storageService = SecureStorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    if (token == null) throw Exception("Not authenticated");
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // --- Authentication (same as before) ---
  Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );
    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['access_token'];
      await _storageService.saveToken(token);
      return token;
    } else {
      throw Exception('Failed to log in');
    }
  }

  Future<void> logout() async {
    await _storageService.deleteToken();
  }

  // --- Admin: User Creation ---
  Future<void> createStudent(StudentCreate data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/create_student'),
      headers: await _getHeaders(),
      body: jsonEncode(data.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create student: ${response.body}');
    }
  }

  Future<void> createFaculty(FacultyCreate data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/create_faculty'),
      headers: await _getHeaders(),
      body: jsonEncode(data.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create faculty: ${response.body}');
    }
  }

  Future<void> createCounselor(CounselorCreate data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/create_counselor'),
      headers: await _getHeaders(),
      body: jsonEncode(data.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create counselor: ${response.body}');
    }
  }

  // --- Admin: Data Retrieval ---
  Future<List<StudentProfile>> getAllStudents() async {
    final response = await http.get(Uri.parse('$baseUrl/students'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => StudentProfile.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load students');
    }
  }

  Future<List<FacultyProfile>> getAllFaculty() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/faculty'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => FacultyProfile.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load faculty');
    }
  }

  Future<List<CounselorProfile>> getAllCounselors() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/counselors'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => CounselorProfile.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load counselors');
    }
  }

  // --- Student: Personal Data ---
  Future<StudentProfile> getMyStudentData() async {
    final response = await http.get(Uri.parse('$baseUrl/students/me'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return StudentProfile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load your student data');
    }
  }
}

// Helper classes to convert Dart objects to JSON for the API
class StudentCreate {
  final String username, password, studentId, name, financialStatus;
  final double initialAttendance, initialGrade;
  StudentCreate({required this.username, required this.password, required this.studentId, required this.name, required this.initialAttendance, required this.initialGrade, required this.financialStatus});
  Map<String, dynamic> toJson() => {'username': username, 'password': password, 'student_id': studentId, 'name': name, 'initial_attendance': initialAttendance, 'initial_grade': initialGrade, 'financial_status': financialStatus};
}

class FacultyCreate {
  final String username, password, name, department;
  FacultyCreate({required this.username, required this.password, required this.name, required this.department});
  Map<String, dynamic> toJson() => {'username': username, 'password': password, 'name': name, 'department': department};
}

class CounselorCreate {
  final String username, password, name, specialization;
  CounselorCreate({required this.username, required this.password, required this.name, required this.specialization});
  Map<String, dynamic> toJson() => {'username': username, 'password': password, 'name': name, 'specialization': specialization};
}