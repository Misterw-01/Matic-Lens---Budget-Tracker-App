import 'package:flutter/foundation.dart';
import 'package:maticlens/models/budget.dart';
import 'package:maticlens/models/expense.dart';
import 'package:maticlens/services/budget_service.dart';

class BudgetProvider with ChangeNotifier {
  final BudgetService _budgetService;
  List<Budget> _budgets = [];
  bool _isLoading = false;
  String? _errorMessage;

  BudgetProvider(this._budgetService);

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBudgets({int? month, int? year}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _budgets = await _budgetService.getBudgets(month: month, year: year);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load budgets';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrUpdateBudget({
    required String category,
    required double limitAmount,
    required int month,
    required int year,
  }) async {
    _errorMessage = null;

    try {
      final budget = await _budgetService.createOrUpdateBudget(
        category: category,
        limitAmount: limitAmount,
        month: month,
        year: year,
      );

      if (budget != null) {
        final index = _budgets.indexWhere(
          (b) => b.category == category && b.month == month && b.year == year,
        );
        if (index != -1) {
          _budgets[index] = budget;
        } else {
          _budgets.add(budget);
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to save budget';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    _errorMessage = null;

    try {
      final success = await _budgetService.deleteBudget(id);

      if (success) {
        _budgets.removeWhere((b) => b.id == id);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to delete budget';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  double calculateProgress(Budget budget, List<Expense> expenses) {
    final categoryExpenses = expenses.where((e) =>
        e.category == budget.category &&
        e.expenseDate.month == budget.month &&
        e.expenseDate.year == budget.year);

    final totalSpent = categoryExpenses.fold(0.0, (sum, e) => sum + e.amount);
    return totalSpent / budget.limitAmount;
  }

  double calculateSpent(Budget budget, List<Expense> expenses) {
    final categoryExpenses = expenses.where((e) =>
        e.category == budget.category &&
        e.expenseDate.month == budget.month &&
        e.expenseDate.year == budget.year);

    return categoryExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  bool isOverBudget(Budget budget, List<Expense> expenses) => 
      calculateProgress(budget, expenses) > 1.0;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
