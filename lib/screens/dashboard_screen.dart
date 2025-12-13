import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:maticlens/constants/cartegories.dart';
import 'package:maticlens/providers/income_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:maticlens/providers/expense_provider.dart';
import 'package:maticlens/providers/budget_provider.dart';
import 'package:maticlens/providers/auth_provider.dart';
import 'package:maticlens/theme.dart';
import 'package:maticlens/widgets/add_expense_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedFilter = 'This Month';
  final List<String> _filterOptions = [
    'This Month',
    'Last 3 Months',
    'Last 6 Months',
    'All',
  ];

  @override
  void initState() {
    super.initState();
    // Defer the initial filter setup to after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilter(_selectedFilter);
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final expenseProvider = context.read<ExpenseProvider>();
    final incomeProvider = context.read<IncomeProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    // Load data from APIs
    await Future.wait([
      expenseProvider.loadExpenses(),
      incomeProvider.loadIncomes(),
    ]);

    // Load budgets for current month (budgets are usually monthly)
    // We might want to adjust this if we assume budgets adapt to filters,
    // but typically budgets are "this month". Keeping as is for now.
    final now = DateTime.now();
    await budgetProvider.loadBudgets(month: now.month, year: now.year);
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });

    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    if (filter == 'This Month') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (filter == 'Last 3 Months') {
      startDate = DateTime(now.year, now.month - 2, 1); // Current + 2 prev
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (filter == 'Last 6 Months') {
      startDate = DateTime(now.year, now.month - 5, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (filter == 'All') {
      startDate = null;
      endDate = null;
    }

    final expenseProvider = context.read<ExpenseProvider>();
    final incomeProvider = context.read<IncomeProvider>();

    expenseProvider.setFilters(startDate: startDate, endDate: endDate);
    incomeProvider.setFilters(startDate: startDate, endDate: endDate);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final incomeProvider = context.watch<IncomeProvider>();

    final filteredExpenses = expenseProvider.filteredExpenses;
    final totalExpenses = expenseProvider.totalExpenses;
    final totalIncome = incomeProvider.totalIncome;
    final netIncome = totalIncome - totalExpenses;

    final recentExpenses = filteredExpenses.take(5).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
           // padding: AppSpacing.paddingLg,
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${authProvider.currentUser?.name ?? "User"}',
                            style: context.textStyles.headlineMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMMM d').format(DateTime.now()),
                            style: context.textStyles.bodyMedium?.withColor(
                              Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        FluentIcons.add_circle_24_filled,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const AddExpenseSheet(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Net Income / Summary Card
                Card(
                  child: Padding(
                    padding: AppSpacing.paddingLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  FluentIcons.calendar_month_24_regular,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedFilter,
                                    isDense: true,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    style: context.textStyles.titleMedium
                                        ?.withColor(
                                          Theme.of(context).colorScheme.primary,
                                        ),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        _applyFilter(newValue);
                                      }
                                    },
                                    items: _filterOptions
                                        .map<DropdownMenuItem<String>>((
                                          String value,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Net Income',
                          style: context.textStyles.bodyMedium?.withColor(
                            Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(symbol: '\$').format(netIncome),
                          style: context.textStyles.displaySmall?.copyWith(
                            color: netIncome >= 0
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Income',
                                    style: context.textStyles.bodySmall
                                        ?.withColor(
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  Text(
                                    NumberFormat.currency(
                                      symbol: '\$',
                                    ).format(totalIncome),
                                    style: context.textStyles.titleMedium
                                        ?.copyWith(
                                          color: const Color(
                                            0xFF10B981,
                                          ), // Success green
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: Theme.of(context).dividerColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Expenses',
                                    style: context.textStyles.bodySmall
                                        ?.withColor(
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  Text(
                                    NumberFormat.currency(
                                      symbol: '\$',
                                    ).format(totalExpenses),
                                    style: context.textStyles.titleMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Charts
                if (expenseProvider.categoryTotals.isNotEmpty) ...[
                  Text(
                    'Spending by Category',
                    style: context.textStyles.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  CategoryChart(categoryTotals: expenseProvider.categoryTotals),
                  const SizedBox(height: 24),
                ],

                // Budgets
                if (budgetProvider.budgets.isNotEmpty) ...[
                  Text('Budget Overview', style: context.textStyles.titleLarge),
                  const SizedBox(height: 16),
                  ...budgetProvider.budgets.map((budget) {
                    // Always calculate budget progress based on CURRENT MONTH only
                    // regardless of the broader dashboard filter.
                    final now = DateTime.now();
                    final budgetExpenses = filteredExpenses
                        .where(
                          (e) =>
                              e.expenseDate.month == now.month &&
                              e.expenseDate.year == now.year,
                        )
                        .toList();

                    final spent = budgetProvider.calculateSpent(
                      budget,
                      budgetExpenses,
                    );
                    final progress = budgetProvider.calculateProgress(
                      budget,
                      budgetExpenses,
                    );
                    final isOver = progress > 1.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BudgetProgressCard(
                        category: budget.category,
                        spent: spent,
                        limit: budget.limitAmount,
                        progress: progress,
                        isOverBudget: isOver,
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: context.textStyles.titleLarge,
                    ),
                    if (recentExpenses.isNotEmpty)
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (recentExpenses.isEmpty)
                  Center(
                    child: Padding(
                      padding: AppSpacing.paddingXl,
                      child: Column(
                        children: [
                          Icon(
                            FluentIcons.receipt_24_regular,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses found',
                            style: context.textStyles.titleMedium?.withColor(
                              Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...recentExpenses.map(
                    (expense) => ExpenseListTile(expense: expense),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryChart extends StatelessWidget {
  final Map<String, double> categoryTotals;

  const CategoryChart({super.key, required this.categoryTotals});

  @override
  Widget build(BuildContext context) {
    final total = categoryTotals.values.fold(0.0, (sum, val) => sum + val);
    final colors = [
      Theme.of(context).colorScheme.primary,
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF06B6D4),
      const Color(0xFF84CC16),
      const Color(0xFFF97316),
    ];

    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: categoryTotals.entries.toList().asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final percentage = (data.value / total * 100);

                      return PieChartSectionData(
                        value: data.value,
                        title: '${percentage.toStringAsFixed(1)}%',
                        color: colors[index % colors.length],
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: categoryTotals.entries.toList().asMap().entries.map((
                entry,
              ) {
                final index = entry.key;
                final data = entry.value;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(data.key, style: context.textStyles.bodySmall),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetProgressCard extends StatelessWidget {
  final String category;
  final double spent;
  final double limit;
  final double progress;
  final bool isOverBudget;

  const BudgetProgressCard({
    super.key,
    required this.category,
    required this.spent,
    required this.limit,
    required this.progress,
    required this.isOverBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ExpenseCategory.getIcon(category),
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category,
                    style: context.textStyles.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${NumberFormat.currency(symbol: '\$').format(spent)} / ${NumberFormat.currency(symbol: '\$').format(limit)}',
                  style: context.textStyles.bodySmall?.withColor(
                    Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress > 1.0 ? 1.0 : progress,
                minHeight: 8,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  isOverBudget
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseListTile extends StatelessWidget {
  final dynamic expense;

  const ExpenseListTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
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
        title: Text(expense.category, style: context.textStyles.titleMedium),
        subtitle: Text(
          DateFormat('MMM d, y').format(expense.expenseDate),
          style: context.textStyles.bodySmall?.withColor(
            Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          NumberFormat.currency(symbol: '\$').format(expense.amount),
          style: context.textStyles.titleMedium?.bold.withColor(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
