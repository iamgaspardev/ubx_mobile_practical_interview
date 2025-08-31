import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated }

class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  AuthState _authState = AuthState.initial;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  User? get user => _user;
  AuthState get authState => _authState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _authState == AuthState.authenticated && _user != null;
  bool get hasProfileImage => _user?.profileImage != null;

  Future<void> initialize() async {
    _setLoading(true);

    try {
      final hasToken = await _apiService.hasValidToken();
      if (hasToken) {
        await getCurrentUser();
      } else {
        _setAuthState(AuthState.unauthenticated);
      }
    } catch (e) {
      print('Error initializing user provider: $e');
      _setAuthState(AuthState.unauthenticated);
    } finally {
      _setLoading(false);
    }
  }

  // Register user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        _user = response.data!.user;
        _setAuthState(AuthState.authenticated);
        return true;
      } else {
        _setError(response.errorMessage);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login user
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        _user = response.data!.user;
        _setAuthState(AuthState.authenticated);
        return true;
      } else {
        _setError(response.errorMessage);
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _apiService.logout();
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      _user = null;
      _setAuthState(AuthState.unauthenticated);
      _clearError();
      _setLoading(false);
    }
  }

  // Get current user data
  Future<void> getCurrentUser() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getCurrentUser();

      if (response.success && response.data != null) {
        _user = response.data;
        _setAuthState(AuthState.authenticated);
      } else {
        _setError(response.message);
        _setAuthState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setError('Failed to get user data: $e');
      _setAuthState(AuthState.unauthenticated);
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateProfile(
        name: name,
        email: email,
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response.success && response.data != null) {
        _user = response.data;
        notifyListeners();
        return true;
      } else {
        _setError(response.errorMessage);
        return false;
      }
    } catch (e) {
      _setError('Profile update failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (_authState == AuthState.authenticated) {
      await getCurrentUser();
    }
  }

  // Clear all user data and logout
  Future<void> clearUserData() async {
    await _apiService.clearAllData();
    _user = null;
    _setAuthState(AuthState.unauthenticated);
    _clearError();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setAuthState(AuthState state) {
    if (_authState != state) {
      _authState = state;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Get user initials for profile display
  String getUserInitials() {
    return _user?.getInitials() ?? 'U';
  }

  // Get user display name
  String getUserDisplayName() {
    return _user?.name ?? 'User';
  }

  // Get user profile image or null
  String? getProfileImageUrl() {
    return _user?.profileImage;
  }

  // Check if user has a specific email
  bool hasEmail(String email) {
    return _user?.email.toLowerCase() == email.toLowerCase();
  }

  Future<bool> updateProfileImage(String imagePath) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateProfileImage(imagePath);

      if (response.success && response.data != null) {
        _user = response.data;
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to update profile image');
        return false;
      }
    } catch (e) {
      _setError('Profile image update failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeProfileImage() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.removeProfileImage();

      if (response.success && response.data != null) {
        _user = response.data;
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to remove profile image');
        return false;
      }
    } catch (e) {
      _setError('Failed to remove profile image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
