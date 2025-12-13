import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:maticlens/constants/api_constants.dart';
import 'package:maticlens/models/budget.dart';
import 'package:maticlens/services/auth_service.dart';
import 'package:maticlens/services/local_storage_service.dart';

class BudgetService {
  final Dio _dio;
  final AuthService _authService;

  BudgetService(this._authService)
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {
            'Content-Type': ApiConstants.contentTypeJson,
            'Accept': ApiConstants.acceptJson,
          },
          connectTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // Helper to check connectivity
  Future<bool> _isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );
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
        final budgets = data.map((json) => Budget.fromJson(json)).toList();

        if (queryParams.isEmpty) {
          await LocalStorageService.budgetsBox.clear();
        }
        for (var budget in budgets) {
          await LocalStorageService.budgetsBox.put(budget.id, budget);
        }

        return budgets;
      }

      return _getLocalBudgets(month, year);
    } catch (e) {
      debugPrint('Get budgets error: $e');
      return _getLocalBudgets(month, year);
    }
  }

  List<Budget> _getLocalBudgets(int? month, int? year) {
    var budgets = LocalStorageService.budgetsBox.values.toList();
    if (month != null) {
      budgets = budgets.where((b) => b.month == month).toList();
    }
    if (year != null) {
      budgets = budgets.where((b) => b.year == year).toList();
    }
    return budgets;
  }

  Future<Budget?> createOrUpdateBudget({
    required String category,
    required double limitAmount,
    required int month,
    required int year,
  }) async {
    final tempId = 'TEMP_${DateTime.now().millisecondsSinceEpoch}';
    final newBudget = Budget(
      id: tempId,
      userId: '',
      category: category,
      limitAmount: limitAmount,
      month: month,
      year: year,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await LocalStorageService.budgetsBox.put(tempId, newBudget);

    // Check connectivity before attempting network request
    final isConnected = await _isConnected();
    if (!isConnected) {
      debugPrint("No connection - saving offline");
      await LocalStorageService.syncQueueBox.add({
        'type': 'CREATE_OR_UPDATE_BUDGET',
        'temp_id': tempId,
        'data': {
          'category': category,
          'limit_amount': limitAmount,
          'month': month,
          'year': year,
        },
      });
      return newBudget;
    }

    try {
      final response = await _dio.post(
        ApiConstants.budgets,
        data: {
          'category': category,
          'limit_amount': limitAmount,
          'month': month,
          'year': year,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final serverBudget = Budget.fromJson(
          response.data['data'] ?? response.data,
        );
        await LocalStorageService.budgetsBox.delete(tempId);
        await LocalStorageService.budgetsBox.put(serverBudget.id, serverBudget);
        return serverBudget;
      }
    } catch (e) {
      debugPrint('Create/Update budget offline fallback: $e');
    }

    await LocalStorageService.syncQueueBox.add({
      'type': 'CREATE_OR_UPDATE_BUDGET',
      'temp_id': tempId,
      'data': {
        'category': category,
        'limit_amount': limitAmount,
        'month': month,
        'year': year,
      },
    });

    return newBudget;
  }

  Future<bool> deleteBudget(String id) async {
    await LocalStorageService.budgetsBox.delete(id);

    try {
      final response = await _dio.delete(ApiConstants.budgetById(id));
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
    } catch (e) {
      debugPrint('Delete budget error: $e');
    }

    if (!id.startsWith('TEMP_')) {
      await LocalStorageService.syncQueueBox.add({
        'type': 'DELETE_BUDGET',
        'id': id,
      });
    }

    return true;
  }

  // SYNC METHODS
  Future<bool> syncCreateOrUpdate(
    String tempId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(ApiConstants.budgets, data: data);
      // Determine if create or update? Typically create new
      if (response.statusCode == 201 || response.statusCode == 200) {
        final serverBudget = Budget.fromJson(
          response.data['data'] ?? response.data,
        );
        await LocalStorageService.budgetsBox.delete(tempId);
        await LocalStorageService.budgetsBox.put(serverBudget.id, serverBudget);
        return true;
      }
    } catch (e) {
      debugPrint('Sync create/update budget error: $e');
    }
    return false;
  }

  Future<bool> syncDelete(String id) async {
    try {
      final response = await _dio.delete(ApiConstants.budgetById(id));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Sync delete budget error: $e');
    }
    return false;
  }
}
