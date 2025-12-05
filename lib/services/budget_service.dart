import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:maticlens/constants/api_constants.dart';
import 'package:maticlens/models/budget.dart';
import 'package:maticlens/services/auth_service.dart';

class BudgetService {
  final Dio _dio;
  final AuthService _authService;

  BudgetService(this._authService)
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {
            'Content-Type': ApiConstants.contentTypeJson,
            'Accept': ApiConstants.acceptJson,
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<List<Budget>> getBudgets({int? month, int? year}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;

      final response = await _dio.get(
        ApiConstants.budgets,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Budget.fromJson(json)).toList();
      }

      return [];
    } on DioException catch (e) {
      debugPrint('Get budgets error: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Get budgets error: $e');
      return [];
    }
  }

  Future<Budget?> createOrUpdateBudget({
    required String category,
    required double limitAmount,
    required int month,
    required int year,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.budgets, data: {
        'category': category,
        'limit_amount': limitAmount,
        'month': month,
        'year': year,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Budget.fromJson(response.data['data'] ?? response.data);
      }

      return null;
    } on DioException catch (e) {
      debugPrint('Create/Update budget error: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('Create/Update budget error: $e');
      return null;
    }
  }

  Future<bool> deleteBudget(String id) async {
    try {
      final response = await _dio.delete(ApiConstants.budgetById(id));
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      debugPrint('Delete budget error: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('Delete budget error: $e');
      return false;
    }
  }
}
