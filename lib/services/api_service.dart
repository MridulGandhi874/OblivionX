import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/student_model.dart';
import 'secure_storage_service.dart';

class ApiService {
  final SecureStorageService _storageService = SecureStorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8', // ✅ Fixed typo
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Authentication ---
  Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      await _storageService.saveToken(token);
      return token;
    } else {
      throw Exception(
          'Failed to log in. (${response.statusCode}) ${response.body}');
    }
  }

  Future<void> logout() async {
    await _storageService.deleteToken();
  }

  // --- Student Data ---
  Future<List<Student>> getAllStudents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/students'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Student.fromJson(item)).toList();
    } else {
      throw Exception(
          'Failed to load students. (${response.statusCode}) ${response.body}');
    }
  }

  Future<Student> getMyStudentData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/me'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Student.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to load your student data. (${response.statusCode}) ${response.body}');
    }
  }

  // --- Admin Functions ---
  Future<void> createUser(
      String username, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to create user. (${response.statusCode}) ${response.body}');
    }
  }
}
