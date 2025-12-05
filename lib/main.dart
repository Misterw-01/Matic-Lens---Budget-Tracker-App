import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maticlens/theme.dart';
import 'package:maticlens/services/auth_service.dart';
import 'package:maticlens/services/expense_service.dart';
import 'package:maticlens/services/budget_service.dart';
import 'package:maticlens/providers/auth_provider.dart';
import 'package:maticlens/providers/expense_provider.dart';
import 'package:maticlens/providers/budget_provider.dart';
import 'package:maticlens/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => ExpenseProvider(ExpenseService(authService))),
        ChangeNotifierProvider(create: (_) => BudgetProvider(BudgetService(authService))),
      ],
      child: MaterialApp(
        title: 'MaticLens',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
