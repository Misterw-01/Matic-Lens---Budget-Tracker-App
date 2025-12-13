import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:maticlens/constants/api_constants.dart';
import 'package:maticlens/models/expense.dart';
import 'package:maticlens/services/auth_service.dart';
import 'package:maticlens/services/local_storage_service.dart';

class ExpenseService {
  final Dio _dio;
  final AuthService _authService;

  ExpenseService(this._authService)
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
      if (startDate != null)
        queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _dio.get(
        ApiConstants.expenses,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        final expenses = data.map((json) => Expense.fromJson(json)).toList();

        // Cache expenses to Hive
        // Note: For simplicity, we are overwriting/adding. Ideally we sync deletions too.
        // For now, clear box and repopulate if no filters (full sync), or just upsert.
        // If filters are active, we probably shouldn't assume this is the full list.
        // But for offline view, upsert is safer than clear.

        if (queryParams.isEmpty) {
          await LocalStorageService.expensesBox.clear();
        }

        for (var expense in expenses) {
          await LocalStorageService.expensesBox.put(expense.id, expense);
        }

        return expenses;
      }

      return _getLocalExpenses(category, paymentMethod, startDate, endDate);
    } catch (e) {
      debugPrint('Get expenses error: $e');
      return _getLocalExpenses(category, paymentMethod, startDate, endDate);
    }
  }

  List<Expense> _getLocalExpenses(
    String? category,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    var expenses = LocalStorageService.expensesBox.values.toList();

    if (category != null) {
      expenses = expenses.where((e) => e.category == category).toList();
    }
    if (paymentMethod != null) {
      expenses = expenses
          .where((e) => e.paymentMethod == paymentMethod)
          .toList();
    }
    if (startDate != null) {
      expenses = expenses
          .where(
            (e) =>
                e.expenseDate.isAfter(startDate) ||
                e.expenseDate.isAtSameMomentAs(startDate),
          )
          .toList();
    }
    if (endDate != null) {
      expenses = expenses
          .where(
            (e) =>
                e.expenseDate.isBefore(endDate) ||
                e.expenseDate.isAtSameMomentAs(endDate),
          )
          .toList();
    }

    // Sort by date DESC
    expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return expenses;
  }

  Future<Expense?> createExpense({
    required String category,
    required double amount,
    required String note,
    required String paymentMethod,
    required DateTime expenseDate,
  }) async {
    // Optimistic Local Creation
    final tempId = 'TEMP_${DateTime.now().millisecondsSinceEpoch}';
    final newExpense = Expense(
      id: tempId,
      userId: '', // Will be filled by server or ignore
      category: category,
      amount: amount,
      note: note,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await LocalStorageService.expensesBox.put(tempId, newExpense);

    // Check connectivity before attempting network request
    final isConnected = await _isConnected();
    if (!isConnected) {
      debugPrint("No connection - saving offline");
      await LocalStorageService.syncQueueBox.add({
        'type': 'CREATE_EXPENSE',
        'temp_id': tempId,
        'data': {
          'category': category,
          'amount': amount,
          'note': note,
          'payment_method': paymentMethod,
          'expense_date': expenseDate.toIso8601String(),
        },
      });
      return newExpense;
    }

    try {
      final response = await _dio.post(
        ApiConstants.expenses,
        data: {
          'category': category,
          'amount': amount,
          'note': note,
          'payment_method': paymentMethod,
          'expense_date': expenseDate.toIso8601String(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final serverExpense = Expense.fromJson(
          response.data['data'] ?? response.data,
        );
        // Replace temp with server data
        await LocalStorageService.expensesBox.delete(tempId);
        await LocalStorageService.expensesBox.put(
          serverExpense.id,
          serverExpense,
        );
        return serverExpense;
      }
    } catch (e) {
      debugPrint('Create expense offline fallback: $e');
    }

    // Add to Sync Queue
    await LocalStorageService.syncQueueBox.add({
      'type': 'CREATE_EXPENSE',
      'temp_id': tempId,
      'data': {
        'category': category,
        'amount': amount,
        'note': note,
        'payment_method': paymentMethod,
        'expense_date': expenseDate.toIso8601String(),
      },
    });

    return newExpense;
  }

  Future<Expense?> updateExpense({
    required String id,
    String? category,
    double? amount,
    String? note,
    String? paymentMethod,
    DateTime? expenseDate,
  }) async {
    // Optimistic Update
    final existing = LocalStorageService.expensesBox.get(id);
    if (existing != null) {
      final updated = existing.copyWith(
        category: category,
        amount: amount,
        note: note,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
        updatedAt: DateTime.now(),
      );
      await LocalStorageService.expensesBox.put(id, updated);
    }

    try {
      final data = <String, dynamic>{};
      if (category != null) data['category'] = category;
      if (amount != null) data['amount'] = amount;
      if (note != null) data['note'] = note;
      if (paymentMethod != null) data['payment_method'] = paymentMethod;
      if (expenseDate != null)
        data['expense_date'] = expenseDate.toIso8601String();

      final response = await _dio.put(ApiConstants.expenseById(id), data: data);

      if (response.statusCode == 200) {
        final serverExpense = Expense.fromJson(
          response.data['data'] ?? response.data,
        );
        await LocalStorageService.expensesBox.put(
          serverExpense.id,
          serverExpense,
        );
        return serverExpense;
      }
    } catch (e) {
      debugPrint('Update expense offline fallback: $e');
    }

    // Add to Sync Queue (Skip if temp id, logic needs handling for temp IDs in queue, but simpler for now)
    if (!id.startsWith('TEMP_')) {
      await LocalStorageService.syncQueueBox.add({
        'type': 'UPDATE_EXPENSE',
        'id': id,
        'data': {
          if (category != null) 'category': category,
          if (amount != null) 'amount': amount,
          if (note != null) 'note': note,
          if (paymentMethod != null) 'payment_method': paymentMethod,
          if (expenseDate != null)
            'expense_date': expenseDate.toIso8601String(),
        },
      });
    }

    return existing; // Return existing (updated locally) as best effort
  }

  Future<bool> deleteExpense(String id) async {
    await LocalStorageService.expensesBox.delete(id);

    try {
      final response = await _dio.delete(ApiConstants.expenseById(id));
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
    } catch (e) {
      debugPrint('Delete expense offline fallback: $e');
    }

    if (!id.startsWith('TEMP_')) {
      await LocalStorageService.syncQueueBox.add({
        'type': 'DELETE_EXPENSE',
        'id': id,
      });
    }

    return true;
  }

  Future<void> clearCache() async {
    await LocalStorageService.expensesBox.clear();
  }

  // SYNC METHODS
  Future<bool> syncCreate(String tempId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.expenses, data: data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final serverExpense = Expense.fromJson(
          response.data['data'] ?? response.data,
        );
        await LocalStorageService.expensesBox.delete(tempId);
        await LocalStorageService.expensesBox.put(
          serverExpense.id,
          serverExpense,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Sync create expense error: $e');
    }
    return false;
  }

  Future<bool> syncUpdate(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConstants.expenseById(id), data: data);
      if (response.statusCode == 200) {
        final serverExpense = Expense.fromJson(
          response.data['data'] ?? response.data,
        );
        await LocalStorageService.expensesBox.put(
          serverExpense.id,
          serverExpense,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Sync update expense error: $e');
    }
    return false;
  }

  Future<bool> syncDelete(String id) async {
    try {
      final response = await _dio.delete(ApiConstants.expenseById(id));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Sync delete expense error: $e');
    }
    return false;
  }
}
