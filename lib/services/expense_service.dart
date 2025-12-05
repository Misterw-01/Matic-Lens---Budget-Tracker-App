import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:maticlens/constants/api_constants.dart';
import 'package:maticlens/models/expense.dart';
import 'package:maticlens/services/auth_service.dart';

class ExpenseService {
  final Dio _dio;
  final AuthService _authService;
  
  static const _cacheKey = 'cached_expenses';

  ExpenseService(this._authService)
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

  Future<List<Expense>> getExpenses({
    String? category,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _dio.get(
        ApiConstants.expenses,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        final expenses = data.map((json) => Expense.fromJson(json)).toList();
        await _cacheExpenses(expenses);
        return expenses;
      }

      return await _getCachedExpenses();
    } on DioException catch (e) {
      debugPrint('Get expenses error: ${e.message}');
      return await _getCachedExpenses();
    } catch (e) {
      debugPrint('Get expenses error: $e');
      return await _getCachedExpenses();
    }
  }

  Future<Expense?> createExpense({
    required String category,
    required double amount,
    required String note,
    required String paymentMethod,
    required DateTime expenseDate,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.expenses, data: {
        'category': category,
        'amount': amount,
        'note': note,
        'payment_method': paymentMethod,
        'expense_date': expenseDate.toIso8601String(),
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Expense.fromJson(response.data['data'] ?? response.data);
      }

      return null;
    } on DioException catch (e) {
      debugPrint('Create expense error: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('Create expense error: $e');
      return null;
    }
  }

  Future<Expense?> updateExpense({
    required String id,
    String? category,
    double? amount,
    String? note,
    String? paymentMethod,
    DateTime? expenseDate,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (category != null) data['category'] = category;
      if (amount != null) data['amount'] = amount;
      if (note != null) data['note'] = note;
      if (paymentMethod != null) data['payment_method'] = paymentMethod;
      if (expenseDate != null) data['expense_date'] = expenseDate.toIso8601String();

      final response = await _dio.put(
        ApiConstants.expenseById(id),
        data: data,
      );

      if (response.statusCode == 200) {
        return Expense.fromJson(response.data['data'] ?? response.data);
      }

      return null;
    } on DioException catch (e) {
      debugPrint('Update expense error: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('Update expense error: $e');
      return null;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      final response = await _dio.delete(ApiConstants.expenseById(id));
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      debugPrint('Delete expense error: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('Delete expense error: $e');
      return false;
    }
  }

  Future<void> _cacheExpenses(List<Expense> expenses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = expenses.map((e) => e.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Cache expenses error: $e');
    }
  }

  Future<List<Expense>> _getCachedExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) => Expense.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Get cached expenses error: $e');
    }
    return [];
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      debugPrint('Clear cache error: $e');
    }
  }
}
