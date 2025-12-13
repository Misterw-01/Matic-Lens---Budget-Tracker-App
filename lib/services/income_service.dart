import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:maticlens/constants/api_constants.dart';
import 'package:maticlens/models/income.dart';
import 'package:maticlens/services/auth_service.dart';
import 'package:maticlens/services/local_storage_service.dart';

class IncomeService {
  final Dio _dio;
  final AuthService _authService;

  IncomeService(this._authService)
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

  // ---------------------------------------------
  // GET INCOME
  // ---------------------------------------------
  Future<List<Income>> getIncome({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (category != null) params['category'] = category;
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();

      final response = await _dio.get(
        ApiConstants.incomes,
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        final incomeList = data.map((json) => Income.fromJson(json)).toList();

        if (params.isEmpty) {
          await LocalStorageService.incomesBox.clear();
        }
        for (var income in incomeList) {
          await LocalStorageService.incomesBox.put(income.id, income);
        }

        return incomeList;
      }

      return _getLocalIncome(category, startDate, endDate);
    } catch (e) {
      debugPrint("Get income error: $e");
      return _getLocalIncome(category, startDate, endDate);
    }
  }

  List<Income> _getLocalIncome(
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    var incomes = LocalStorageService.incomesBox.values.toList();

    if (category != null) {
      incomes = incomes.where((i) => i.category == category).toList();
    }
    if (startDate != null) {
      incomes = incomes
          .where(
            (i) =>
                i.incomeDate.isAfter(startDate) ||
                i.incomeDate.isAtSameMomentAs(startDate),
          )
          .toList();
    }
    if (endDate != null) {
      incomes = incomes
          .where(
            (i) =>
                i.incomeDate.isBefore(endDate) ||
                i.incomeDate.isAtSameMomentAs(endDate),
          )
          .toList();
    }

    incomes.sort((a, b) => b.incomeDate.compareTo(a.incomeDate));
    return incomes;
  }

  // ---------------------------------------------
  // CREATE INCOME
  // ---------------------------------------------
  Future<Income?> createIncome({
    required String category,
    required double amount,
    required String note,
    String? paymentMethod,
    required DateTime incomeDate,
  }) async {
    final tempId = 'TEMP_${DateTime.now().millisecondsSinceEpoch}';
    final newIncome = Income(
      id: tempId,
      userId: '',
      category: category,
      amount: amount,
      note: note,
      paymentMethod: paymentMethod ?? '',
      incomeDate: incomeDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await LocalStorageService.incomesBox.put(tempId, newIncome);

    // Check connectivity before attempting network request
    final isConnected = await _isConnected();
    if (!isConnected) {
      debugPrint("No connection - saving offline");
      await LocalStorageService.syncQueueBox.add({
        'type': 'CREATE_INCOME',
        'temp_id': tempId,
        'data': {
          'category': category,
          'amount': amount,
          'note': note,
          'income_date': incomeDate.toIso8601String(),
        },
      });
      return newIncome;
    }

    try {
      final response = await _dio.post(
        ApiConstants.incomes,
        data: {
          'category': category,
          'amount': amount,
          'note': note,
          'income_date': incomeDate.toIso8601String(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final serverIncome = Income.fromJson(
          response.data['data'] ?? response.data,
        );
        await LocalStorageService.incomesBox.delete(tempId);
        await LocalStorageService.incomesBox.put(serverIncome.id, serverIncome);
        return serverIncome;
      }
    } catch (e) {
      debugPrint("Create income offline fallback: $e");
    }

    await LocalStorageService.syncQueueBox.add({
      'type': 'CREATE_INCOME',
      'temp_id': tempId,
      'data': {
        'category': category,
        'amount': amount,
        'note': note,
        'income_date': incomeDate.toIso8601String(),
      },
    });

    return newIncome;
  }

  // ---------------------------------------------
  // UPDATE INCOME
  // ---------------------------------------------
  Future<Income?> updateIncome({
    required String id,
    String? category,
    double? amount,
    String? note,
    // String? paymentMethod,
    DateTime? incomeDate,
  }) async {
    final existing = LocalStorageService.incomesBox.get(id);
    if (existing != null) {
      final updated = existing.copyWith(
        category: category,
        amount: amount,
        note: note,
        incomeDate: incomeDate,
        updatedAt: DateTime.now(),
      );
      await LocalStorageService.incomesBox.put(id, updated);
    }

    try {
      final body = <String, dynamic>{};
      if (category != null) body['category'] = category;
      if (amount != null) body['amount'] = amount;
      if (note != null) body['note'] = note;
      if (incomeDate != null)
        body['income_date'] = incomeDate.toIso8601String();

      final response = await _dio.put(ApiConstants.incomeById(id), data: body);

      if (response.statusCode == 200) {
        final serverIncome = Income.fromJson(
          response.data['data'] ?? response.data,
        );
        await LocalStorageService.incomesBox.put(serverIncome.id, serverIncome);
        return serverIncome;
      }
    } catch (e) {
      debugPrint("Update income offline fallback: $e");
    }

    if (!id.startsWith('TEMP_')) {
      await LocalStorageService.syncQueueBox.add({
        'type': 'UPDATE_INCOME',
        'id': id,
        'data': {
          if (category != null) 'category': category,
          if (amount != null) 'amount': amount,
          if (note != null) 'note': note,
          if (incomeDate != null) 'income_date': incomeDate.toIso8601String(),
        },
      });
    }

    return existing;
  }

  // ---------------------------------------------
  // DELETE INCOME
  // ---------------------------------------------
  Future<bool> deleteIncome(String id) async {
    await LocalStorageService.incomesBox.delete(id);

    try {
      final response = await _dio.delete(ApiConstants.incomeById(id));
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
    } catch (e) {
      debugPrint("Delete income offline fallback: $e");
    }

    if (!id.startsWith('TEMP_')) {
      await LocalStorageService.syncQueueBox.add({
        'type': 'DELETE_INCOME',
        'id': id,
      });
    }

    return true;
  }

  // ---------------------------------------------
  // CACHE INCOME LIST
  // ---------------------------------------------

  Future<void> clearCache() async {
    await LocalStorageService.incomesBox.clear();
  }

  // SYNC METHODS
  Future<bool> syncCreate(String tempId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.incomes, data: data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final serverIncome = Income.fromJson(
          response.data['data'] ?? response.data,
        );
        await LocalStorageService.incomesBox.delete(tempId);
        await LocalStorageService.incomesBox.put(serverIncome.id, serverIncome);
        return true;
      }
    } catch (e) {
      debugPrint('Sync create income error: $e');
    }
    return false;
  }

  Future<bool> syncUpdate(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConstants.incomeById(id), data: data);
      if (response.statusCode == 200) {
        final serverIncome = Income.fromJson(
          response.data['data'] ?? response.data,
        );
        await LocalStorageService.incomesBox.put(serverIncome.id, serverIncome);
        return true;
      }
    } catch (e) {
      debugPrint('Sync update income error: $e');
    }
    return false;
  }

  Future<bool> syncDelete(String id) async {
    try {
      final response = await _dio.delete(ApiConstants.incomeById(id));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Sync delete income error: $e');
    }
    return false;
  }

  double calculateBalance({
    required double totalIncome,
    required double totalExpenses,
  }) {
    return totalIncome - totalExpenses;
  }
}
