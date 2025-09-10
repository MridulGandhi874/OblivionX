// lib/providers/faculty_provider.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/class_profile.dart';
import '../models/profiles/student_profile.dart';

class FacultyProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ClassProfile> _classes = [];
  List<StudentProfile> _studentsInSelectedClass = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ClassProfile> get classes => _classes;
  List<StudentProfile> get studentsInSelectedClass => _studentsInSelectedClass;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetches the classes assigned to the currently logged-in faculty member
  Future<void> fetchMyClasses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _classes = await _apiService.getMyClasses();
    } catch (e) {
      _errorMessage = "Failed to load your classes.";
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  // Fetches the list of students for a specific class ID
  Future<void> fetchStudentsForClass(String classId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // We notify here to show a loading indicator on the student list part
    try {
      _studentsInSelectedClass = await _apiService.getStudentsInClass(classId);
    } catch (e) {
      _errorMessage = "Failed to load students for this class.";
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  // Faculty can update student grade
  Future<void> updateStudentGrade(String studentId, double newGrade) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notify to show loading indicator if desired

    try {
      final updatedStudent = await _apiService.updateStudentGradeByFaculty(studentId, newGrade);
      // Find and replace the updated student in the current class's student list
      int index = _studentsInSelectedClass.indexWhere((s) => s.studentId == studentId);
      if (index != -1) {
        _studentsInSelectedClass[index] = updatedStudent;
      }
    } catch (e) {
      _errorMessage = "Failed to update student grade: $e";
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  // Clears all data on logout
  void clearData() {
    _classes = [];
    _studentsInSelectedClass = [];
    _errorMessage = null;
    notifyListeners();
  }
}