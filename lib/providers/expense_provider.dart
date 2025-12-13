import 'package:flutter/foundation.dart';
import 'package:maticlens/models/expense.dart';
import 'package:maticlens/services/expense_service.dart';
import 'package:maticlens/services/sync_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService;
  final SyncService _syncService;
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedCategory;
  String? _selectedPaymentMethod;
  DateTime? _startDate;
  DateTime? _endDate;

  ExpenseProvider(this._expenseService, this._syncService);

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  String? get selectedPaymentMethod => _selectedPaymentMethod;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  List<Expense> get filteredExpenses {
    var filtered = _expenses;

    if (_selectedCategory != null) {
      filtered = filtered
          .where((e) => e.category == _selectedCategory)
          .toList();
    }

    if (_selectedPaymentMethod != null) {
      filtered = filtered
          .where((e) => e.paymentMethod == _selectedPaymentMethod)
          .toList();
    }

    if (_startDate != null) {
      filtered = filtered
          .where(
            (e) =>
                e.expenseDate.isAfter(_startDate!) ||
                e.expenseDate.isAtSameMomentAs(_startDate!),
          )
          .toList();
    }

    if (_endDate != null) {
      filtered = filtered
          .where(
            (e) =>
                e.expenseDate.isBefore(_endDate!) ||
                e.expenseDate.isAtSameMomentAs(_endDate!),
          )
          .toList();
    }

    return filtered..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  }

  double get totalExpenses =>
      filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

  Map<String, double> get categoryTotals {
    final totals = <String, double>{};
    for (var expense in filteredExpenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Trigger sync first if there are pending items
      if (_syncService.hasPendingSync) {
        await _syncService.sync();
      }

      _expenses = await _expenseService.getExpenses();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load expenses';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense({
    required String category,
    required double amount,
    required String note,
    required String paymentMethod,
    required DateTime expenseDate,
  }) async {
    _errorMessage = null;

    try {
      final expense = await _expenseService.createExpense(
        category: category,
        amount: amount,
        note: note,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
      );

      if (expense != null) {
        _expenses.add(expense);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to create expense';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense({
    required String id,
    String? category,
    double? amount,
    String? note,
    String? paymentMethod,
    DateTime? expenseDate,
  }) async {
    _errorMessage = null;

    try {
      final updatedExpense = await _expenseService.updateExpense(
        id: id,
        category: category,
        amount: amount,
        note: note,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
      );

      if (updatedExpense != null) {
        final index = _expenses.indexWhere((e) => e.id == id);
        if (index != -1) {
          _expenses[index] = updatedExpense;
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = 'Failed to update expense';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    _errorMessage = null;

    try {
      final success = await _expenseService.deleteExpense(id);

      if (success) {
        _expenses.removeWhere((e) => e.id == id);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to delete expense';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  void setFilters({
    String? category,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _selectedCategory = category;
    _selectedPaymentMethod = paymentMethod;
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedPaymentMethod = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
