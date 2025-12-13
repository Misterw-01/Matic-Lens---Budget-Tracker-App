import 'package:matcher/matcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:maticlens/screens/splash_screen.dart';
import 'package:maticlens/services/auth_service.dart';
import 'package:maticlens/services/expense_service.dart';
import 'package:maticlens/services/budget_service.dart';
import 'package:maticlens/services/income_service.dart';
import 'package:maticlens/services/sync_service.dart';
import 'package:maticlens/providers/auth_provider.dart';
import 'package:maticlens/providers/expense_provider.dart';
import 'package:maticlens/providers/budget_provider.dart';
import 'package:maticlens/providers/income_provider.dart';
import 'package:maticlens/theme.dart';
import 'package:maticlens/services/local_storage_service.dart';

void main() async {
  // Ensure binding before setting system UI overlays
  // Ensure binding before setting system UI overlays
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Storage
  await LocalStorageService.init();

  // Optional: Force transparent status bar globally on app start
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final expenseService = ExpenseService(authService);
    final budgetService = BudgetService(authService);
    final incomeService = IncomeService(authService);

    // Initialize Sync Service
    final syncService = SyncService(
      expenseService,
      incomeService,
      budgetService,
    );
    syncService.init();

    return MultiProvider(
      providers: [
        // Provide SyncService so it can be accessed by providers and UI
        Provider<SyncService>.value(value: syncService),

        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(expenseService, syncService),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(budgetService, syncService),
        ),
        ChangeNotifierProvider(
          create: (_) => IncomeProvider(incomeService, syncService),
        ),
      ],
      child: MaterialApp(
        title: 'MaticLens',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),

        // ⚡ GLOBAL STATUS BAR FIX
        // ⚡ GLOBAL STATUS BAR FIX
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              // Android: Dark icons for light mode, Light icons for dark mode
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              // iOS: Light brightness (dark content) for light mode, Dark brightness (light content) for dark mode
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:maticlens/providers/income_provider.dart';
import 'package:maticlens/services/income_service.dart';
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
        ChangeNotifierProvider(create: (_) => IncomeProvider(IncomeService(authService)),
        )],
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
*/
