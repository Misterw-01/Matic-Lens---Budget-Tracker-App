import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:maticlens/screens/income_screen.dart';
import 'package:provider/provider.dart';
import 'package:maticlens/providers/expense_provider.dart';
import 'package:maticlens/providers/budget_provider.dart';
import 'package:maticlens/screens/dashboard_screen.dart';
import 'package:maticlens/screens/expenses_screen.dart';
import 'package:maticlens/screens/budgets_screen.dart';
import 'package:maticlens/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ExpensesScreen(),
    IncomeScreen(),
    BudgetsScreen(),
    ProfileScreen(),

  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenseProvider = context.read<ExpenseProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    
    await Future.wait([
      expenseProvider.loadExpenses(),
      budgetProvider.loadBudgets(
        month: DateTime.now().month,
        year: DateTime.now().year,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(FluentIcons.home_24_regular),
            selectedIcon: Icon(FluentIcons.home_24_filled),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(FluentIcons.receipt_24_regular),
            selectedIcon: Icon(FluentIcons.receipt_24_filled),
            label: 'Expenses',
          ),

          //add Income Screen
          NavigationDestination(
            icon: Icon(FluentIcons.money_24_regular),
            selectedIcon: Icon(FluentIcons.money_24_filled),
            label: 'Income',
          ),

          NavigationDestination(
            icon: Icon(FluentIcons.target_24_regular),
            selectedIcon: Icon(FluentIcons.target_24_filled),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(FluentIcons.person_24_regular),
            selectedIcon: Icon(FluentIcons.person_24_filled),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
