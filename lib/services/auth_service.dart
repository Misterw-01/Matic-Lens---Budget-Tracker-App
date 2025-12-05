import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:maticlens/constants/api_constants.dart';
import 'package:maticlens/models/user.dart';

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';

  AuthService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {
            'Content-Type': ApiConstants.contentTypeJson,
            'Accept': ApiConstants.acceptJson,
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )),
        _storage = const FlutterSecureStorage() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('API Error: ${error.response?.statusCode} - ${error.message}');
        return handler.next(error);
      },
    ));
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Error reading token: $e');
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userIdKey);
    } catch (e) {
      debugPrint('Error deleting token: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = response.data['token'] as String?;
        final userData = response.data['user'] as Map<String, dynamic>?;

        if (token != null) {
          await saveToken(token);
        }

        if (userData != null) {
          final user = User.fromJson(userData);
          return {'success': true, 'user': user};
        }
      }

      return {'success': false, 'message': 'Registration failed'};
    } on DioException catch (e) {
      debugPrint('Register error: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Registration failed',
      };
    } catch (e) {
      debugPrint('Register error: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'] as String?;
        final userData = response.data['user'] as Map<String, dynamic>?;

        if (token != null) {
          await saveToken(token);
        }

        if (userData != null) {
          final user = User.fromJson(userData);
          return {'success': true, 'user': user};
        }
      }

      return {'success': false, 'message': 'Login failed'};
    } on DioException catch (e) {
      debugPrint('Login error: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Invalid credentials',
      };
    } catch (e) {
      debugPrint('Login error: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _dio.get(ApiConstants.user);

      if (response.statusCode == 200) {
        return User.fromJson(response.data['user'] ?? response.data);
      }

      return null;
    } on DioException catch (e) {
      debugPrint('Get user error: ${e.response?.statusCode}');
      if (e.response?.statusCode == 401) {
        await deleteToken();
      }
      return null;
    } catch (e) {
      debugPrint('Get user error: $e');
      return null;
    }
  }

  Future<bool> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
      await deleteToken();
      return true;
    } catch (e) {
      debugPrint('Logout error: $e');
      await deleteToken();
      return true;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
}
