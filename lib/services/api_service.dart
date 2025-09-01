import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ubx_practical_mobile/models/api_response.dart';
import 'package:ubx_practical_mobile/models/auth_response.dart';
import '../models/user_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String BASE_URL = 'http://192.168.1.111:8000/api';
  late final Dio _dio;

  // secure storage
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'com.ubx.practical.mobile',
    ),
  );

  String? _deviceId;
  String? _cachedToken;
  bool _isInitialized = false;

  // Token management keys
  static const String _tokenKey = 'auth_token_v2';
  static const String _tokenTimestampKey = 'token_timestamp';
  static const int _tokenExpiryHours = 24;

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

    await _initializeDeviceId();
    _cachedToken = await getToken();
    _setupInterceptors();
    _isInitialized = true;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_deviceId != null) {
            options.headers['X-Device-ID'] = _deviceId;
          }

          final authEndpoints = ['/login', '/register'];
          final isAuthEndpoint = authEndpoints.any(
            (endpoint) => options.path.contains(endpoint),
          );

          if (!isAuthEndpoint && _cachedToken != null) {
            options.headers['Authorization'] = 'Bearer $_cachedToken';
          }

          handler.next(options);
        },

        onResponse: (response, handler) {
          handler.next(response);
        },

        onError: (error, handler) async {
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
      _deviceId = 'fallback-device-id-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Token Management
  Future<void> saveToken(String token) async {
    try {
      if (!_isValidTokenFormat(token)) {
        throw Exception('Invalid token format');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      await Future.wait([
        _storage.write(key: _tokenKey, value: token),
        _storage.write(key: _tokenTimestampKey, value: timestamp),
      ]);

      _cachedToken = token;
    } catch (e) {
      throw Exception('Failed to save authentication token securely: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      if (_cachedToken != null && await _isTokenValid()) {
        return _cachedToken;
      }

      final token = await _storage.read(key: _tokenKey);
      final timestampStr = await _storage.read(key: _tokenTimestampKey);

      if (token == null || timestampStr == null) {
        return null;
      }

      final timestamp = int.tryParse(timestampStr) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursOld = (now - timestamp) / (1000 * 60 * 60);

      if (hoursOld > _tokenExpiryHours) {
        // clearing token expired
        await clearToken();
        return null;
      }

      _cachedToken = token;
      return token;
    } catch (e) {
      print('Error retrieving token: $e');
      return null;
    }
  }

  Future<bool> _isTokenValid() async {
    try {
      final timestampStr = await _storage.read(key: _tokenTimestampKey);
      if (timestampStr == null) return false;

      final timestamp = int.tryParse(timestampStr) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursOld = (now - timestamp) / (1000 * 60 * 60);

      return hoursOld <= _tokenExpiryHours;
    } catch (e) {
      return false;
    }
  }

  bool _isValidTokenFormat(String token) {
    final parts = token.split('|');
    return parts.length == 2 && parts[0].isNotEmpty && parts[1].length >= 40;
  }

  Future<void> clearToken() async {
    try {
      await Future.wait([
        _storage.delete(key: _tokenKey),
        _storage.delete(key: _tokenTimestampKey),
      ]);
      _cachedToken = null;
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Authentication Methods
  Future<ApiResponse<AuthResponse>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
        return ApiResponse<AuthResponse>(
          success: false,
          message: 'All fields are required',
        );
      }

      if (!_isValidEmail(email)) {
        return ApiResponse<AuthResponse>(
          success: false,
          message: 'Please enter a valid email address',
        );
      }

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
      if (email.trim().isEmpty || password.isEmpty) {
        return ApiResponse<AuthResponse>(
          success: false,
          message: 'Email and password are required',
        );
      }

      final requestData = {
        'email': email.trim().toLowerCase(),
        'password': password,
      };

      final response = await _dio.post('/login', data: requestData);
      return _handleAuthResponse(response);
    } on DioException catch (e) {
      return _handleDioError<AuthResponse>(e);
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Login failed: $e',
      );
    }
  }

  ApiResponse<AuthResponse> _handleAuthResponse(Response response) {
    try {
      if (response.data != null && response.data['success'] == true) {
        final authResponse = AuthResponse.fromJson(response.data['data']);

        if (!_isValidTokenFormat(authResponse.token)) {
          return ApiResponse<AuthResponse>(
            success: false,
            message: 'Received invalid token format from server',
          );
        }

        saveToken(authResponse.token);

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
    } catch (e) {
      print('Error handling auth response: $e');
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Failed to process authentication response',
      );
    }
  }

  Future<ApiResponse<bool>> logout() async {
    try {
      try {
        await _dio.post('/logout');
      } catch (e) {
        print('Server logout failed');
      }

      await clearToken();

      return ApiResponse<bool>(
        success: true,
        message: 'Logged out successfully',
        data: true,
      );
    } catch (e) {
      await clearToken();

      return ApiResponse<bool>(
        success: true,
        message: 'Logged out locally',
        data: true,
      );
    }
  }

  // Profile Methods
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _dio.get('/user');

      if (response.data != null && response.data['success'] == true) {
        final user = User.fromJson(response.data['data']['user']);

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
      print('Unexpected error getting user: $e');
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
      final data = <String, dynamic>{};

      if (name != null && name.isNotEmpty) {
        data['name'] = name.trim();
      }

      if (email != null && email.isNotEmpty) {
        data['email'] = email.trim().toLowerCase();
      }

      if (currentPassword != null && currentPassword.isNotEmpty) {
        data['current_password'] = currentPassword;

        if (password != null && password.isNotEmpty) {
          data['password'] = password;
          data['password_confirmation'] = passwordConfirmation ?? password;
        }
      }

      final response = await _dio.put('/profile', data: data);

      if (response.data != null && response.data['success'] == true) {
        final user = User.fromJson(response.data['data']['user']);

        // print('Profile updated successfully');

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

  Future<ApiResponse<User>> updateProfileImage(String imagePath) async {
    try {
      print('\nUPLOADING PROFILE IMAGE');
      print('Image path: $imagePath');

      final file = File(imagePath);

      if (!await file.exists()) {
        throw Exception('Image file not found');
      }

      final fileSize = await file.length();
      const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
      if (fileSize > maxSizeInBytes) {
        throw Exception('Image size must be less than 5MB');
      }

      final extension = imagePath.split('.').last.toLowerCase();
      const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
      if (!allowedExtensions.contains(extension)) {
        throw Exception('Only JPG, PNG, and WebP images are allowed');
      }

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: 'profile_image.$extension',
        ),
      });

      final response = await _dio.post(
        '/profile/image',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.data != null && response.data['success'] == true) {
        final user = User.fromJson(response.data['data']['user']);

        print('Profile image updated successfully');

        return ApiResponse<User>(
          success: true,
          message:
              response.data['message'] ?? 'Profile image updated successfully',
          data: user,
        );
      } else {
        return ApiResponse<User>(
          success: false,
          message:
              response.data?['message'] ?? 'Failed to update profile image',
        );
      }
    } on DioException catch (e) {
      return _handleDioError<User>(e);
    } catch (e) {
      return ApiResponse<User>(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<User>> removeProfileImage() async {
    try {
      final response = await _dio.delete('/profile/image');

      if (response.data != null && response.data['success'] == true) {
        final user = User.fromJson(response.data['data']['user']);

        return ApiResponse<User>(
          success: true,
          message:
              response.data['message'] ?? 'Profile image removed successfully',
          data: user,
        );
      } else {
        return ApiResponse<User>(
          success: false,
          message:
              response.data?['message'] ?? 'Failed to remove profile image',
        );
      }
    } on DioException catch (e) {
      return _handleDioError<User>(e);
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: 'Failed to remove profile image: $e',
      );
    }
  }

  // Helper Methods
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  ApiResponse<T> _handleDioError<T>(DioException error) {
    String message = 'Network error occurred';
    Map<String, List<String>>? errors;

    if (error.response != null) {
      final responseData = error.response!.data;

      if (responseData is Map<String, dynamic>) {
        message = responseData['message'] ?? message;

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

      switch (error.response!.statusCode) {
        case 400:
          message = 'Bad request. Please check your input.';
          break;
        case 401:
          message = 'Please login again to continue';
          break;
        case 403:
          message = 'Access denied. You do not have permission.';
          break;
        case 404:
          message = 'Resource not found.';
          break;
        case 413:
          message = 'File too large. Please choose a smaller image.';
          break;
        case 422:
          message = errors != null && errors.isNotEmpty
              ? 'Please check your input and try again'
              : message;
          break;
        case 429:
          message = 'Too many requests. Please wait and try again.';
          break;
        case 500:
          message = 'Server error. Please try again later.';
          break;
        case 503:
          message = 'Service unavailable. Please try again later.';
          break;
      }
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message =
              'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection. Please check your network.';
          break;
        case DioExceptionType.cancel:
          message = 'Request was cancelled.';
          break;
        default:
          message = 'Network error. Please try again.';
      }
    }

    return ApiResponse<T>(success: false, message: message, errors: errors);
  }

  Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
      _cachedToken = null;
    } catch (e) {
      print('Error clearing all data: $e');
    }
  }

  bool get isInitialized => _isInitialized;
  String? get deviceId => _deviceId;
  String get baseUrl => BASE_URL;
}
