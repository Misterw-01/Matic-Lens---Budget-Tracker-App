import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maticlens/models/expense.dart';
import 'package:maticlens/models/budget.dart';
import 'package:maticlens/models/income.dart';

class LocalStorageService {
  static const String expensesBoxName = 'expenses';
  static const String budgetsBoxName = 'budgets';
  static const String incomesBoxName = 'incomes';
  static const String syncQueueBoxName = 'sync_queue';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(BudgetAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(IncomeAdapter());
    // Register generic adapter for sync queue if needed or just use Map/JSON

    // Open Boxes
    await Hive.openBox<Expense>(expensesBoxName);
    await Hive.openBox<Budget>(budgetsBoxName);
    await Hive.openBox<Income>(incomesBoxName);
    await Hive.openBox(syncQueueBoxName); // Generic box for sync queue
  }

  // Generic methods to access boxes
  static Box<Expense> get expensesBox => Hive.box<Expense>(expensesBoxName);
  static Box<Budget> get budgetsBox => Hive.box<Budget>(budgetsBoxName);
  static Box<Income> get incomesBox => Hive.box<Income>(incomesBoxName);
  static Box get syncQueueBox => Hive.box(syncQueueBoxName);

  // Clear all data (e.g. on logout specific to user? For now clear all)
  static Future<void> clearAll() async {
    await expensesBox.clear();
    await budgetsBox.clear();
    await incomesBox.clear();
    await syncQueueBox.clear();
  }
}
