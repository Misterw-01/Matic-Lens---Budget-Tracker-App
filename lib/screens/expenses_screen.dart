import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:maticlens/constants/cartegories.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:maticlens/providers/expense_provider.dart';
import 'package:maticlens/theme.dart';
import 'package:maticlens/widgets/add_expense_sheet.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.filter_24_regular),
            onPressed: () => _showFilterSheet(context),
          ),
          IconButton(
            icon: const Icon(FluentIcons.add_24_regular),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddExpenseSheet(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => expenseProvider.loadExpenses(),
        child: expenseProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : expenseProvider.filteredExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FluentIcons.receipt_24_regular,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No expenses found',
                          style: context.textStyles.titleMedium?.withColor(
                            Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const AddExpenseSheet(),
                          ),
                          child: const Text('Add your first expense'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      if (expenseProvider.selectedCategory != null ||
                          expenseProvider.selectedPaymentMethod != null ||
                          expenseProvider.startDate != null ||
                          expenseProvider.endDate != null)
                        Container(
                          padding: AppSpacing.paddingMd,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Row(
                            children: [
                              Icon(
                                FluentIcons.filter_24_filled,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Filters active',
                                  style: context.textStyles.bodyMedium?.withColor(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: expenseProvider.clearFilters,
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: AppSpacing.paddingMd,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${expenseProvider.filteredExpenses.length} transactions',
                              style: context.textStyles.bodyMedium?.withColor(
                                Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Total: ${NumberFormat.currency(symbol: '\$').format(expenseProvider.totalExpenses)}',
                              style: context.textStyles.titleMedium?.bold.withColor(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: AppSpacing.paddingMd,
                          itemCount: expenseProvider.filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenseProvider.filteredExpenses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Icon(
                                    ExpenseCategory.getIcon(expense.category),
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        expense.category,
                                        style: context.textStyles.titleMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      NumberFormat.currency(symbol: '\$').format(expense.amount),
                                      style: context.textStyles.titleMedium?.bold.withColor(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (expense.note.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        expense.note,
                                        style: context.textStyles.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          PaymentMethod.getIcon(expense.paymentMethod),
                                          size: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          PaymentMethod.getLabel(expense.paymentMethod),
                                          style: context.textStyles.bodySmall?.withColor(
                                            Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          FluentIcons.calendar_24_regular,
                                          size: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('MMM d, y').format(expense.expenseDate),
                                          style: context.textStyles.bodySmall?.withColor(
                                            Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(FluentIcons.delete_24_regular, size: 20),
                                  color: Theme.of(context).colorScheme.error,
                                  onPressed: () => _confirmDelete(context, expense.id),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final expenseProvider = context.read<ExpenseProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterSheet(
        initialCategory: expenseProvider.selectedCategory,
        initialPaymentMethod: expenseProvider.selectedPaymentMethod,
        initialStartDate: expenseProvider.startDate,
        initialEndDate: expenseProvider.endDate,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String expenseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final expenseProvider = context.read<ExpenseProvider>();
              final success = await expenseProvider.deleteExpense(expenseId);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Expense deleted' : 'Failed to delete expense'),
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class FilterSheet extends StatefulWidget {
  final String? initialCategory;
  final String? initialPaymentMethod;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const FilterSheet({
    super.key,
    this.initialCategory,
    this.initialPaymentMethod,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedPaymentMethod = widget.initialPaymentMethod;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _applyFilters() {
    final expenseProvider = context.read<ExpenseProvider>();
    expenseProvider.setFilters(
      category: _selectedCategory,
      paymentMethod: _selectedPaymentMethod,
      startDate: _startDate,
      endDate: _endDate,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter Expenses', style: context.textStyles.headlineSmall),
                IconButton(
                  icon: const Icon(FluentIcons.dismiss_24_regular),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Category', style: context.textStyles.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                ...ExpenseCategory.all.map((category) {
                  return ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (_) => setState(() => _selectedCategory = category),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
            Text('Payment Method', style: context.textStyles.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedPaymentMethod == null,
                  onSelected: (_) => setState(() => _selectedPaymentMethod = null),
                ),
                ...PaymentMethod.all.map((method) {
                  return ChoiceChip(
                    label: Text(PaymentMethod.getLabel(method)),
                    selected: _selectedPaymentMethod == method,
                    onSelected: (_) => setState(() => _selectedPaymentMethod = method),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
            Text('Date Range', style: context.textStyles.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectStartDate(context),
                    child: Text(_startDate != null
                        ? DateFormat('MMM d, y').format(_startDate!)
                        : 'Start Date'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectEndDate(context),
                    child: Text(_endDate != null
                        ? DateFormat('MMM d, y').format(_endDate!)
                        : 'End Date'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: const Text('Apply Filters'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
