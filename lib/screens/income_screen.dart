import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:maticlens/constants/income_categories.dart'; // NEW
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:maticlens/providers/income_provider.dart'; // NEW
import 'package:maticlens/theme.dart';
import 'package:maticlens/widgets/add_income_sheet.dart'; // NEW

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  @override
  void initState() {
    super.initState();
    // Clear any filters that may have been set by the dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncomeProvider>().clearFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final incomeProvider = context.watch<IncomeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
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
              builder: (_) => const AddIncomeSheet(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger sync and then reload incomes
          await incomeProvider.loadIncomes();
        },
        child: incomeProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : incomeProvider.filteredIncomes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FluentIcons.money_24_regular,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No income records found',
                      style: context.textStyles.titleMedium?.withColor(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const AddIncomeSheet(),
                      ),
                      child: const Text('Add your first income'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  if (incomeProvider.selectedCategory != null ||
                      incomeProvider.startDate != null ||
                      incomeProvider.endDate != null)
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
                            onPressed: incomeProvider.clearFilters,
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),

                  /// Summary Row
                  Container(
                    padding: AppSpacing.paddingMd,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${incomeProvider.filteredIncomes.length} transactions',
                          style: context.textStyles.bodyMedium?.withColor(
                            Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Total: ${NumberFormat.currency(symbol: '\$').format(incomeProvider.totalIncome)}',
                          style: context.textStyles.titleMedium?.bold.withColor(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Income list
                  Expanded(
                    child: ListView.builder(
                      padding: AppSpacing.paddingMd,
                      itemCount: incomeProvider.filteredIncomes.length,
                      itemBuilder: (context, index) {
                        final income = incomeProvider.filteredIncomes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: Icon(
                                IncomeCategory.getIcon(income.category),
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    income.category,
                                    style: context.textStyles.titleMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(
                                    symbol: '\$',
                                  ).format(income.amount),
                                  style: context.textStyles.titleMedium?.bold
                                      .withColor(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (income.note.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    income.note,
                                    style: context.textStyles.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      FluentIcons.calendar_24_regular,
                                      size: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat(
                                        'MMM d, y',
                                      ).format(income.incomeDate),
                                      style: context.textStyles.bodySmall
                                          ?.withColor(
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                FluentIcons.delete_24_regular,
                                size: 20,
                              ),
                              color: Theme.of(context).colorScheme.error,
                              onPressed: () =>
                                  _confirmDelete(context, income.id),
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
    final incomeProvider = context.read<IncomeProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => IncomeFilterSheet(
        initialCategory: incomeProvider.selectedCategory,
        initialStartDate: incomeProvider.startDate,
        initialEndDate: incomeProvider.endDate,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String incomeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income'),
        content: const Text(
          'Are you sure you want to delete this income entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final incomeProvider = context.read<IncomeProvider>();
              final success = await incomeProvider.deleteIncome(incomeId);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Income deleted' : 'Failed to delete income',
                    ),
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

// ----------------------------------------------------------------------
// FILTER SHEET FOR INCOME
// ----------------------------------------------------------------------

class IncomeFilterSheet extends StatefulWidget {
  final String? initialCategory;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const IncomeFilterSheet({
    super.key,
    this.initialCategory,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<IncomeFilterSheet> createState() => _IncomeFilterSheetState();
}

class _IncomeFilterSheetState extends State<IncomeFilterSheet> {
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
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
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _applyFilters() {
    final provider = context.read<IncomeProvider>();
    provider.setFilters(
      category: _selectedCategory,
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
                Text('Filter Income', style: context.textStyles.headlineSmall),
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
                ...IncomeCategory.all.map((category) {
                  return ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
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
                    child: Text(
                      _startDate != null
                          ? DateFormat('MMM d, y').format(_startDate!)
                          : 'Start Date',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectEndDate(context),
                    child: Text(
                      _endDate != null
                          ? DateFormat('MMM d, y').format(_endDate!)
                          : 'End Date',
                    ),
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
