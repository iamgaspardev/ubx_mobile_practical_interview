// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ubx_practical_mobile/models/auth_response.dart';
import '../models/user_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String BASE_URL = 'http://192.168.1.111:8000/api';
  late final Dio _dio;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  String? _deviceId;
  String? _cachedToken;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: BASE_URL,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Get device ID
    await _initializeDeviceId();

    // Get cached token
    _cachedToken = await getToken();

    _setupInterceptors();
    _isInitialized = true;

    print('ApiService initialized - BaseURL: $BASE_URL');
    print('Device ID: $_deviceId');
    print('Has cached token: ${_cachedToken != null}');
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add device ID to all requests
          if (_deviceId != null) {
            options.headers['X-Device-ID'] = _deviceId;
          }

          // Add auth token if available (except for auth endpoints)
          final authEndpoints = ['/login', '/register'];
          final isAuthEndpoint = authEndpoints.any(
            (endpoint) => options.path.contains(endpoint),
          );

          if (!isAuthEndpoint && _cachedToken != null) {
            options.headers['Authorization'] = 'Bearer $_cachedToken';
          }

          print('\n🚀 REQUEST');
          print('${options.method} ${options.baseUrl}${options.path}');
          print('Headers: ${options.headers}');
          if (options.data != null) {
            print('Data: ${options.data}');
          }

          handler.next(options);
        },

        onResponse: (response, handler) {
          print('\n✅ RESPONSE');
          print('Status: ${response.statusCode}');
          print('Data: ${response.data}');
          handler.next(response);
        },

        onError: (error, handler) async {
          print('\n❌ ERROR');
          print('Status: ${error.response?.statusCode}');
          print('Message: ${error.message}');
          print('Data: ${error.response?.data}');

          // Handle token expiration
          if (error.response?.statusCode == 401) {
            await clearToken();
            _cachedToken = null;
          }

          handler.next(error);
        },
      ),
    );
  }

  Future<void> _initializeDeviceId() async {
    if (_deviceId != null) return;

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor ?? 'unknown-ios-device';
      } else {
        _deviceId = 'unknown-platform';
      }
    } catch (e) {
      print('Error getting device ID: $e');
      _deviceId = 'fallback-device-id-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Token Management
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: 'auth_token', value: token);
      _cachedToken = token;
      print('✅ Token saved successfully');
    } catch (e) {
      print('❌ Error saving token: $e');
      throw Exception('Failed to save authentication token');
    }
  }

  Future<String?> getToken() async {
    try {
      if (_cachedToken != null) return _cachedToken;

      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        _cachedToken = token;
        print('✅ Token retrieved from storage');
      }
      return token;
    } catch (e) {
      print('❌ Error retrieving token: $e');
      return null;
    }
  }

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: 'auth_token');
      _cachedToken = null;
      print('✅ Token cleared successfully');
    } catch (e) {
      print('❌ Error clearing token: $e');
    }
  }

  Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Authentication API Methods
  Future<ApiResponse<AuthResponse>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print('\n🔐 REGISTERING USER');
      print('Name: $name');
      print('Email: $email');

      final requestData = {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      };

      final response = await _dio.post('/register', data: requestData);

      return _handleAuthResponse(response);
    } on DioException catch (e) {
      return _handleDioError<AuthResponse>(e);
    } catch (e) {
      print('❌ Unexpected registration error: $e');
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Registration failed: $e',
      );
    }
  }

  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('\n🔐 LOGGING IN USER');
      print('Email: $email');

      final requestData = {
        'email': email.trim().toLowerCase(),
        'password': password,
      };

      final response = await _dio.post('/login', data: requestData);

      return _handleAuthResponse(response);
    } on DioException catch (e) {
      return _handleDioError<AuthResponse>(e);
    } catch (e) {
      print('❌ Unexpected login error: $e');
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Login failed: $e',
      );
    }
  }

  ApiResponse<AuthResponse> _handleAuthResponse(Response response) {
    if (response.data != null && response.data['success'] == true) {
      final authResponse = AuthResponse.fromJson(response.data['data']);

      // Save token for future requests
      saveToken(authResponse.token);

      print('✅ Authentication successful');
      print('User: ${authResponse.user.name} (${authResponse.user.email})');

      return ApiResponse<AuthResponse>(
        success: true,
        message: response.data['message'] ?? 'Authentication successful',
        data: authResponse,
      );
    } else {
      return ApiResponse<AuthResponse>(
        success: false,
        message: response.data?['message'] ?? 'Authentication failed',
      );
    }
  }

  Future<ApiResponse<bool>> logout() async {
    try {
      print('\n🚪 LOGGING OUT USER');

      // Try to call logout endpoint
      try {
        await _dio.post('/logout');
        print('✅ Server logout successful');
      } catch (e) {
        print('⚠️ Server logout failed, continuing with local logout: $e');
      }

      // Always clear local token
      await clearToken();

      return ApiResponse<bool>(
        success: true,
        message: 'Logged out successfully',
        data: true,
      );
    } catch (e) {
      print('❌ Logout error: $e');
      // Even if there's an error, clear the token locally
      await clearToken();

      return ApiResponse<bool>(
        success: true,
        message: 'Logged out locally',
        data: true,
      );
    }
  }

  // Profile API Methods
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      print('\n👤 GETTING CURRENT USER');

      final response = await _dio.get('/user');

      if (response.data != null && response.data['success'] == true) {
        final user = User.fromJson(response.data['data']['user']);

        print('✅ User data retrieved');
        print('User: ${user.name} (${user.email})');

        return ApiResponse<User>(
          success: true,
          message: response.data['message'] ?? 'User data retrieved',
          data: user,
        );
      } else {
        return ApiResponse<User>(
          success: false,
          message: response.data?['message'] ?? 'Failed to get user data',
        );
      }
    } on DioException catch (e) {
      return _handleDioError<User>(e);
    } catch (e) {
      print('❌ Unexpected error getting user: $e');
      return ApiResponse<User>(
        success: false,
        message: 'Failed to get user data: $e',
      );
    }
  }

  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async {
    try {
      print('\n✏️ UPDATING PROFILE');

      final data = <String, dynamic>{};

      if (name != null && name.isNotEmpty) {
        data['name'] = name.trim();
        print('Updating name: $name');
      }

      if (email != null && email.isNotEmpty) {
        data['email'] = email.trim().toLowerCase();
        print('Updating email: $email');
      }

      if (currentPassword != null && currentPassword.isNotEmpty) {
        data['current_password'] = currentPassword;
        print('Changing password');

        if (password != null && password.isNotEmpty) {
          data['password'] = password;
          data['password_confirmation'] = passwordConfirmation ?? password;
        }
      }

      final response = await _dio.put('/profile', data: data);

      if (response.data != null && response.data['success'] == true) {
        final user = User.fromJson(response.data['data']['user']);

        print('✅ Profile updated successfully');

        return ApiResponse<User>(
          success: true,
          message: response.data['message'] ?? 'Profile updated successfully',
          data: user,
        );
      } else {
        return ApiResponse<User>(
          success: false,
          message: response.data?['message'] ?? 'Failed to update profile',
        );
      }
    } on DioException catch (e) {
      return _handleDioError<User>(e);
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: 'Profile update failed: $e',
      );
    }
  }

  // Error Handling
  ApiResponse<T> _handleDioError<T>(DioException error) {
    String message = 'Network error occurred';
    Map<String, List<String>>? errors;

    print('❌ DioException Type: ${error.type}');
    print('❌ Status Code: ${error.response?.statusCode}');
    print('❌ Response Data: ${error.response?.data}');

    if (error.response != null) {
      final responseData = error.response!.data;

      if (responseData is Map<String, dynamic>) {
        message = responseData['message'] ?? message;

        // Handle validation errors
        if (responseData['errors'] != null) {
          try {
            errors = Map<String, List<String>>.from(
              responseData['errors'].map(
                (key, value) => MapEntry(
                  key,
                  List<String>.from(value is List ? value : [value.toString()]),
                ),
              ),
            );
          } catch (e) {
            print('Error parsing validation errors: $e');
          }
        }
      }

      // Handle specific status codes
      switch (error.response!.statusCode) {
        case 400:
          message = 'Bad request. Please check your input.';
          break;
        case 401:
          message = 'Authentication failed. Please login again.';
          break;
        case 403:
          message = 'Access denied. You do not have permission.';
          break;
        case 404:
          message = 'Resource not found.';
          break;
        case 422:
          message = errors != null && errors.isNotEmpty
              ? 'Validation failed. Please check your input.'
              : message;
          break;
        case 429:
          message = 'Too many requests. Please try again later.';
          break;
        case 500:
          message = 'Server error. Please try again later.';
          break;
        case 503:
          message = 'Service unavailable. Please try again later.';
          break;
      }
    } else {
      // Handle network errors
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          message =
              'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.sendTimeout:
          message = 'Request timeout. Please try again.';
          break;
        case DioExceptionType.receiveTimeout:
          message = 'Response timeout. Please try again.';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection. Please check your network.';
          break;
        case DioExceptionType.cancel:
          message = 'Request was cancelled.';
          break;
        default:
          message = 'Network error: ${error.message}';
      }
    }

    return ApiResponse<T>(success: false, message: message, errors: errors);
  }

  // Utility Methods
  Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
      _cachedToken = null;
      print('✅ All secure storage data cleared');
    } catch (e) {
      print('❌ Error clearing all data: $e');
    }
  }

  bool get isInitialized => _isInitialized;
  String? get deviceId => _deviceId;
  String get baseUrl => BASE_URL;
}
