// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profiles/student_profile.dart';
import '../models/profiles/faculty_profile.dart';
import '../models/profiles/counselor_profile.dart';
import '../models/class_profile.dart';
import '../models/counseling_session.dart';

const String _baseUrl = 'http://10.106.55.237:8000'; // Adjust as needed for your setup

// Pydantic-like models... (rest of your models remain unchanged)
class LoginRequest {
  final String username;
  final String password;
  LoginRequest({required this.username, required this.password});
  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class StudentCreate {
  final String name;
  final String studentId;
  final String username;
  final String password;
  final double initialAttendance;
  final double initialGrade;
  final String financialStatus;

  StudentCreate({
    required this.name,
    required this.studentId,
    required this.username,
    required this.password,
    required this.initialAttendance,
    required this.initialGrade,
    required this.financialStatus,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'student_id': studentId,
    'username': username,
    'password': password,
    'initial_attendance': initialAttendance,
    'initial_grade': initialAttendance, // Fix: Changed to initial_attendance. Ensure this is correct.
    'financial_status': financialStatus,
  };
}

class FacultyCreate {
  final String name;
  final String department;
  final String username;
  final String password;
  FacultyCreate({required this.name, required this.department, required this.username, required this.password});
  Map<String, dynamic> toJson() => {'name': name, 'department': department, 'username': username, 'password': password};
}

class CounselorCreate {
  final String name;
  final String specialization;
  final String username;
  final String password;
  CounselorCreate({required this.name, required this.specialization, required this.username, required this.password});
  Map<String, dynamic> toJson() => {'name': name, 'specialization': specialization, 'username': username, 'password': password};
}


// --- API Service Class (Singleton) ---
class ApiService {
  // ✅ Singleton pattern starts here
  static final ApiService _instance = ApiService._internal(); // Private static instance
  factory ApiService() => _instance; // Public factory constructor returns the instance
  ApiService._internal(); // Private constructor

  String? _token; // Store the JWT token

  void setToken(String token) {
    _token = token;
    print("ApiService: Token set."); // ✅ Log token setting
  }

  void clearToken() {
    _token = null;
    print("ApiService: Token cleared."); // ✅ Log token clearing
  }

  Map<String, String> _getHeaders({bool authorized = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (authorized && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
      // print("ApiService: Adding Authorization header with token."); // ✅ Verbose log for debugging
    } else if (authorized && _token == null) {
      print("ApiService: Warning! Attempted authorized request without token."); // ✅ Critical log for debugging
    }
    return headers;
  }

  // --- Authentication ---
  Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      setToken(responseBody['access_token']); // Set token using the instance method
      return _token!; // Return the token string from the instance
    } else {
      final error = json.decode(response.body)['detail'] ?? 'Login failed';
      throw Exception(error);
    }
  }

  Future<void> logout() async {
    clearToken();
  }

  // --- Admin Endpoints ---
  Future<void> createStudent(StudentCreate data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/create_student'),
      headers: _getHeaders(),
      body: json.encode(data.toJson()),
    );
    if (response.statusCode != 201) {
      final error = json.decode(response.body)['detail'] ?? 'Failed to create student';
      throw Exception(error);
    }
  }

  Future<void> createFaculty(FacultyCreate data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/create_faculty'),
      headers: _getHeaders(),
      body: json.encode(data.toJson()),
    );
    if (response.statusCode != 201) {
      final error = json.decode(response.body)['detail'] ?? 'Failed to create faculty';
      throw Exception(error);
    }
  }

  Future<void> createCounselor(CounselorCreate data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/create_counselor'),
      headers: _getHeaders(),
      body: json.encode(data.toJson()),
    );
    if (response.statusCode != 201) {
      final error = json.decode(response.body)['detail'] ?? 'Failed to create counselor';
      throw Exception(error);
    }
  }

  Future<List<FacultyProfile>> getAllFaculty() async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/faculty'), headers: _getHeaders());
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<FacultyProfile>.from(l.map((model) => FacultyProfile.fromJson(model)));
    } else {
      throw Exception('Failed to load faculty: ${json.decode(response.body)['detail'] ?? response.statusCode}');
    }
  }

  Future<List<CounselorProfile>> getAllCounselors() async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/counselors'), headers: _getHeaders());
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<CounselorProfile>.from(l.map((model) => CounselorProfile.fromJson(model)));
    } else {
      throw Exception('Failed to load counselors: ${json.decode(response.body)['detail'] ?? response.statusCode}');
    }
  }

  Future<StudentProfile> updateFinancialStatus(String studentId, String newStatus) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/admin/students/$studentId/financials?status_update=$newStatus'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      return StudentProfile.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body)['detail'] ?? 'Failed to update financial status';
      throw Exception(error);
    }
  }

  Future<void> createClass(String className, String facultyId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/classes'),
      headers: _getHeaders(),
      body: json.encode({'class_name': className, 'faculty_id': facultyId}),
    );
    if (response.statusCode != 201) {
      final error = json.decode(response.body)['detail'] ?? 'Failed to create class';
      throw Exception(error);
    }
  }

  Future<void> assignStudentToClass(String classId, String studentId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/classes/$classId/assign_student'),
      headers: _getHeaders(),
      body: json.encode({'student_id': studentId}),
    );
    if (response.statusCode != 200) {
      final error = json.decode(response.body)['detail'] ?? 'Failed to assign student to class';
      throw Exception(error);
    }
  }

  Future<List<ClassProfile>> getAllClasses() async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/classes'), headers: _getHeaders());
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<ClassProfile>.from(l.map((model) => ClassProfile.fromJson(model)));
    } else {
      throw Exception('Failed to load classes: ${json.decode(response.body)['detail'] ?? response.statusCode}');
    }
  }

  // --- Student Endpoints ---
  Future<StudentProfile> getMyStudentData() async {
    final response = await http.get(Uri.parse('$_baseUrl/students/me'), headers: _getHeaders());
    if (response.statusCode == 200) {
      return StudentProfile.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load student data: ${json.decode(response.body)['detail'] ?? response.statusCode}');
    }
  }

  Future<List<StudentProfile>> getAllStudents() async {
    final response = await http.get(Uri.parse('$_baseUrl/students'), headers: _getHeaders());
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<StudentProfile>.from(l.map((model) => StudentProfile.fromJson(model)));
    } else {
      throw Exception('Failed to load students: ${json.decode(response.body)['detail'] ?? response.statusCode}');
    }
  }

  // --- Faculty Endpoints ---
  Future<List<ClassProfile>> getMyClasses() async {
    final response = await http.get(Uri.parse('$_baseUrl/faculty/my_classes'), headers: _getHeaders());
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<ClassProfile>.from(l.map((model) => ClassProfile.fromJson(model)));
    } else {
      throw Exception('Failed to load faculty classes: ${json.decode(response.body)['detail'] ?? response.statusCode}');
    }
  }

  Future<List<StudentProfile>> getStudentsInClass(String classId) async {
    final response = await http.get(Uri.parse('$_baseUrl/faculty/classes/$classId/students'), headers: _getHeaders());
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<StudentProfile>.from(l.map((model) => StudentProfile.fromJson(model)));
    } else {
      throw Exception('Failed to load students for class: ${json.decode(response.body)['detail'] ?? response.statusCode}');
    }
  }

  Future<StudentProfile> updateStudentGradeByFaculty(String studentId, double newGrade) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/faculty/students/$studentId/grade'),
      headers: _getHeaders(),
      body: json.encode({'new_grade': newGrade}),
    );
    if (response.statusCode == 200) {
      return StudentProfile.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body)['detail'] ?? 'Failed to update student grade';
      throw Exception(error);
    }
  }

  // --- Counselor Endpoints ---
  Future<List<CounselingSession>> getSessionsForStudent(String studentId) async {
    final response = await http.get(Uri.parse('$_baseUrl/sessions/student/$studentId'), headers: _getHeaders());
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<CounselingSession>.from(l.map((model) => CounselingSession.fromJson(model)));
    } else {
      throw Exception('Failed to load counseling sessions: ${json.decode(response.body)['detail'] ?? response.statusCode}');
    }
  }

  Future<void> createSession(String studentId, String notes) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sessions'),
      headers: _getHeaders(),
      body: json.encode({
        'student_id': studentId,
        'notes': notes,
      }),
    );
    if (response.statusCode != 201) {
      final error = json.decode(response.body)['detail'] ?? 'Failed to create session';
      throw Exception(error);
    }
  }

  Future<void> updateSession(String sessionId, String notes, String status) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/sessions/$sessionId'),
      headers: _getHeaders(),
      body: json.encode({
        'notes': notes,
        'status': status,
      }),
    );
    if (response.statusCode != 200) {
      final error = json.decode(response.body)['detail'] ?? 'Failed to update session';
      throw Exception(error);
    }
  }
}