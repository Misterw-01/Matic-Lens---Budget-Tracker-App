class ApiConstants {
  // Base URL - Update this with your Laravel backend URL
  //static const baseUrl = 'http://localhost:8000/api';

  //static const baseUrl = 'http://127.0.0.1:8000/api';
  //   static const baseUrl = 'http://10.0.2.2:8000/api';
  //
  //
  //   // Auth endpoints
  //   static const register = '/register';
  //   static const login = '/login';
  //   static const logout = '/logout';
  //   static const user = '/user';
  //
  //   // Expense endpoints
  //   static const expenses = '/expenses';
  //   static String expenseById(String id) => '/expenses/$id';
  //
  //   // Budget endpoints
  //   static const budgets = '/budgets';
  //   static String budgetById(String id) => '/budgets/$id';
  //
  //   // Headers
  //   static const contentTypeJson = 'application/json';
  //   static const acceptJson = 'application/json';
  // }
  static const baseUrl = 'http://10.0.2.2:8000/api';


  // Auth endpoints
  static const register = '/register';
  static const login = '/login';
  static const logout = '/logout';
  static const user = '/user';
  static const updatePassword = '/user/password';

  // Expense endpoints
  static const expenses = '/expenses';
  static String expenseById(String id) => '/expenses/$id';

  // Income endpoints
  static const incomes = '/incomes';
  static String incomeById(String id) => '/incomes/$id';

  // Budget endpoints
  static const budgets = '/budgets';
  static String budgetById(String id) => '/budgets/$id';

  // Headers
  static const contentTypeJson = 'application/json';
  static const acceptJson = 'application/json';
}
