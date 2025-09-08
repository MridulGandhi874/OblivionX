// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

enum AuthState {
  unauthenticated,
  authenticated,
  authenticating,
  error
}

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SecureStorageService _storageService = SecureStorageService();

  // --- THIS IS THE FIX ---
  // The state now correctly uses 'AuthState.unauthenticated'
  AuthState _authState = AuthState.unauthenticated;
  String? _token;
  String? _errorMessage;
  String? _userRole;

  AuthState get authState => _authState;
  String? get errorMessage => _errorMessage;
  String? get userRole => _userRole;

  Future<bool> login(String username, String password) async {
    _authState = AuthState.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _apiService.login(username, password);
      _token = token;

      Map<String, dynamic> payload = JwtDecoder.decode(_token!);
      _userRole = payload['role'];

      _authState = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _authState = AuthState.error;
      _errorMessage = "Login failed. Please check your credentials.";
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _token = null;
    _userRole = null;
    _authState = AuthState.unauthenticated;
    notifyListeners();
  }
}