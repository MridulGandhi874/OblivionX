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
  // ✅ Changed to use the singleton instance
  final ApiService _apiService = ApiService();
  final SecureStorageService _storageService = SecureStorageService();

  AuthState _authState = AuthState.unauthenticated;
  String? _token;
  String? _errorMessage;
  String? _userRole;

  AuthState get authState => _authState;
  String? get errorMessage => _errorMessage;
  String? get userRole => _userRole;

  AuthProvider() {
    _checkStoredToken();
  }

  Future<void> _checkStoredToken() async {
    _authState = AuthState.authenticating;
    notifyListeners();
    _token = await _storageService.getToken();
    if (_token != null && !JwtDecoder.isExpired(_token!)) {
      _apiService.setToken(_token!); // Set the token in the *singleton* ApiService
      Map<String, dynamic> payload = JwtDecoder.decode(_token!);
      _userRole = payload['role'];
      _authState = AuthState.authenticated;
      print("Auth: Token found and valid. User role: $_userRole");
    } else {
      _token = null;
      _authState = AuthState.unauthenticated;
      print("Auth: No valid token found. Unauthenticated.");
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _authState = AuthState.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      print("Auth: Attempting login for $username...");
      // ApiService().login will now call setToken on the singleton instance directly
      final String fetchedToken = await _apiService.login(username, password);
      _token = fetchedToken; // AuthProvider also keeps its own copy

      await _storageService.saveToken(_token!);
      // No need to explicitly call _apiService.setToken here again,
      // as it's already done inside ApiService.login()
      // But keeping it wouldn't hurt, just ensure it's always the singleton instance.

      Map<String, dynamic> payload = JwtDecoder.decode(_token!);
      _userRole = payload['role'];

      _authState = AuthState.authenticated;
      print("Auth: Login successful. User role: $_userRole");
      notifyListeners();
      return true;
    } catch (e) {
      _authState = AuthState.error;
      _errorMessage = "Login failed. Please check your credentials. (Error: $e)";
      print("Auth: Login failed for $username: $e");
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    print("Auth: Logging out...");
    _apiService.logout(); // This clears the token in the *singleton* ApiService
    await _storageService.deleteToken();
    _token = null;
    _userRole = null;
    _authState = AuthState.unauthenticated;
    print("Auth: Logout complete.");
    notifyListeners();
  }
}