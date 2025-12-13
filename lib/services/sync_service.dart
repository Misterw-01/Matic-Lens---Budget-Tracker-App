import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:maticlens/services/budget_service.dart';
import 'package:maticlens/services/expense_service.dart';
import 'package:maticlens/services/income_service.dart';
import 'package:maticlens/services/local_storage_service.dart';

class SyncService {
  final ExpenseService _expenseService;
  final IncomeService _incomeService;
  final BudgetService _budgetService;

  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  // Notifier for sync status - UI can listen to this
  final ValueNotifier<bool> syncStatusNotifier = ValueNotifier<bool>(false);

  SyncService(this._expenseService, this._incomeService, this._budgetService);

  // Expose sync status
  bool get isSyncing => _isSyncing;

  // Check if there are pending items to sync
  bool get hasPendingSync => LocalStorageService.syncQueueBox.isNotEmpty;

  void init() {
    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      // connectivity_plus 6.0+ returns List<ConnectivityResult>
      bool isConnected = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      if (isConnected) {
        sync();
      }
    });

    // Initial sync check
    sync();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    syncStatusNotifier.dispose();
  }

  // Made public so it can be called manually from UI/providers
  Future<void> sync() async {
    if (_isSyncing) return;

    // Check connectivity again just to be sure
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = connectivityResult.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );

    if (!isConnected) return;

    _isSyncing = true;
    syncStatusNotifier.value = true;
    debugPrint('Starting sync...');

    try {
      final box = LocalStorageService.syncQueueBox;
      if (box.isEmpty) {
        _isSyncing = false;
        syncStatusNotifier.value = false;
        debugPrint('Sync queue empty.');
        return;
      }

      // Snapshot keys to iterate
      final keys = box.keys.toList();

      for (var key in keys) {
        final item = box.get(key);
        if (item == null || item is! Map) {
          await box.delete(key); // Cleanup invalid data
          continue;
        }

        // Convert Map<dynamic, dynamic> to Map<String, dynamic> safely
        final Map<String, dynamic> data = Map<String, dynamic>.from(item);
        final String type = data['type'];
        bool success = false;

        debugPrint('Syncing item: $type');

        switch (type) {
          // EXPENSE
          case 'CREATE_EXPENSE':
            success = await _expenseService.syncCreate(
              data['temp_id'],
              Map<String, dynamic>.from(data['data']),
            );
            break;
          case 'UPDATE_EXPENSE':
            success = await _expenseService.syncUpdate(
              data['id'],
              Map<String, dynamic>.from(data['data']),
            );
            break;
          case 'DELETE_EXPENSE':
            success = await _expenseService.syncDelete(data['id']);
            break;

          // INCOME
          case 'CREATE_INCOME':
            success = await _incomeService.syncCreate(
              data['temp_id'],
              Map<String, dynamic>.from(data['data']),
            );
            break;
          case 'UPDATE_INCOME':
            success = await _incomeService.syncUpdate(
              data['id'],
              Map<String, dynamic>.from(data['data']),
            );
            break;
          case 'DELETE_INCOME':
            success = await _incomeService.syncDelete(data['id']);
            break;

          // BUDGET
          case 'CREATE_OR_UPDATE_BUDGET':
            success = await _budgetService.syncCreateOrUpdate(
              data['temp_id'],
              Map<String, dynamic>.from(data['data']),
            );
            break;
          case 'DELETE_BUDGET':
            success = await _budgetService.syncDelete(data['id']);
            break;
        }

        if (success) {
          debugPrint('Sync item processed successfully: $key');
          await box.delete(key);
        } else {
          debugPrint('Sync item failed: $key');
          // Best effort approach - continue syncing other items
          // even if one fails
        }
      }
    } catch (e) {
      debugPrint('Sync logic error: $e');
    } finally {
      _isSyncing = false;
      syncStatusNotifier.value = false;
      debugPrint('Sync finished.');
    }
  }
}
