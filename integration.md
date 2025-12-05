# MaticLens - Complete Integration Guide

## 🎯 System Overview

MaticLens is a full-stack expense tracking application with:
- **Frontend**: Flutter 3.x mobile app (iOS & Android)
- **Backend**: Laravel 11 REST API
- **Authentication**: Laravel Sanctum with token-based auth
- **State Management**: Provider pattern
- **Local Caching**: SharedPreferences for offline support
- **Secure Storage**: flutter_secure_storage for auth tokens

---

## 📱 Flutter Frontend Architecture

### Project Structure

```
lib/
├── constants/
│   ├── api_constants.dart      # API endpoints & base URL
│   └── categories.dart          # Expense categories & payment methods
├── models/
│   ├── user.dart               # User model
│   ├── expense.dart            # Expense model
│   └── budget.dart             # Budget model
├── services/
│   ├── auth_service.dart       # Authentication API calls
│   ├── expense_service.dart    # Expense CRUD operations
│   └── budget_service.dart     # Budget CRUD operations
├── providers/
│   ├── auth_provider.dart      # Auth state management
│   ├── expense_provider.dart   # Expense state management
│   └── budget_provider.dart    # Budget state management
├── screens/
│   ├── splash_screen.dart      # Initial auth check
│   ├── login_screen.dart       # User login
│   ├── register_screen.dart    # User registration
│   ├── main_navigation.dart    # Bottom nav container
│   ├── dashboard_screen.dart   # Home with charts
│   ├── expenses_screen.dart    # Expense list & filters
│   ├── budgets_screen.dart     # Budget management
│   └── profile_screen.dart     # User profile
├── widgets/
│   └── add_expense_sheet.dart  # Bottom sheet for adding expenses
├── main.dart                   # App entry point
└── theme.dart                  # Design system & colors
```

### Key Features

1. **Authentication Flow**
   - Splash screen checks for saved token
   - Login/Register with email & password
   - Token stored securely in flutter_secure_storage
   - Auto-redirect on 401 errors

2. **Dashboard**
   - Monthly expense summary
   - Category breakdown pie chart (fl_chart)
   - Budget progress indicators
   - Recent transactions list

3. **Expense Management**
   - Add/Edit/Delete expenses
   - Filter by category, payment method, date range
   - Local caching for offline access
   - Pull-to-refresh

4. **Budget Tracking**
   - Set budgets by category & month
   - Visual progress bars
   - Over-budget warnings
   - Real-time calculations

5. **Design System**
   - Sophisticated monochrome theme
   - Teal accent color (#14B8A6)
   - Fluent UI icons
   - Inter font family
   - Border-based flat design

---

## 🔧 Backend Architecture

### Laravel 11 Structure

```
app/
├── Http/
│   └── Controllers/
│       ├── AuthController.php      # Login, register, logout
│       ├── ExpenseController.php   # Expense CRUD
│       └── BudgetController.php    # Budget CRUD
└── Models/
    ├── User.php                    # User model with Sanctum
    ├── Expense.php                 # Expense model
    └── Budget.php                  # Budget model

database/
└── migrations/
    ├── xxxx_create_expenses_table.php
    └── xxxx_create_budgets_table.php

routes/
└── api.php                         # API route definitions
```

### Database Schema

**users**
- id (PK)
- name
- email (unique)
- password (hashed)
- created_at, updated_at

**expenses**
- id (PK)
- user_id (FK)
- category
- amount (decimal)
- note (text, nullable)
- payment_method (cash/card/bank_transfer)
- expense_date (date)
- created_at, updated_at

**budgets**
- id (PK)
- user_id (FK)
- category
- limit_amount (decimal)
- month (1-12)
- year
- created_at, updated_at
- UNIQUE(user_id, category, month, year)

---

## 🔄 Authentication Flow (End-to-End)

### 1. User Registration

**Flutter** → **Laravel**

```
User fills registration form
    ↓
AuthProvider.register() called
    ↓
AuthService.register() sends POST to /api/register
    ↓
Laravel validates data
    ↓
User created in database
    ↓
Sanctum token generated
    ↓
Token + User data returned
    ↓
Flutter saves token in secure storage
    ↓
User redirected to Dashboard
```

**Flutter Code**:
```dart
final success = await authProvider.register(
  name: name,
  email: email,
  password: password,
);
```

**Laravel Endpoint**:
```php
POST /api/register
Body: { name, email, password, password_confirmation }
Response: { user, token }
```

### 2. User Login

**Flutter** → **Laravel**

```
User enters credentials
    ↓
AuthProvider.login() called
    ↓
AuthService.login() sends POST to /api/login
    ↓
Laravel verifies credentials
    ↓
Sanctum token generated
    ↓
Token + User data returned
    ↓
Flutter saves token in secure storage
    ↓
User redirected to Dashboard
```

### 3. Protected API Calls

**Flutter** → **Laravel**

```
App needs to fetch expenses
    ↓
ExpenseService.getExpenses() called
    ↓
Dio interceptor adds token to headers:
  Authorization: Bearer {token}
    ↓
GET /api/expenses with token
    ↓
Laravel auth:sanctum middleware validates token
    ↓
If valid: data returned
If invalid (401): Flutter catches error
    ↓
On 401: Flutter clears token & redirects to login
```

### 4. Logout

**Flutter** → **Laravel**

```
User clicks logout
    ↓
AuthProvider.logout() called
    ↓
POST /api/logout with token
    ↓
Laravel deletes token from database
    ↓
Flutter clears secure storage
    ↓
User redirected to Login screen
```

---

## 🌐 API Integration Examples

### Create Expense (Complete Flow)

**Flutter Side:**

1. User taps "Add Expense" button
2. Bottom sheet modal appears with form
3. User fills: amount, category, payment method, date, note
4. User taps "Add Expense" button
5. Form validation runs
6. `ExpenseProvider.addExpense()` called
7. `ExpenseService.createExpense()` sends API request

```dart
// In AddExpenseSheet widget
final success = await expenseProvider.addExpense(
  category: 'Food & Dining',
  amount: 45.50,
  note: 'Lunch at restaurant',
  paymentMethod: 'card',
  expenseDate: DateTime.now(),
);
```

**API Request:**
```http
POST http://localhost:8000/api/expenses
Headers:
  Authorization: Bearer 1|xxxxxx
  Content-Type: application/json
  Accept: application/json

Body:
{
  "category": "Food & Dining",
  "amount": 45.50,
  "note": "Lunch at restaurant",
  "payment_method": "card",
  "expense_date": "2024-01-15T00:00:00.000Z"
}
```

**Laravel Processing:**

1. Middleware validates token
2. Controller validates input data
3. Expense created with user_id from authenticated user
4. Expense returned in response

```php
// In ExpenseController@store
$expense = $request->user()->expenses()->create($validated);
return response()->json(['data' => $expense], 201);
```

**Laravel Response:**
```json
{
  "data": {
    "id": 1,
    "user_id": 1,
    "category": "Food & Dining",
    "amount": "45.50",
    "note": "Lunch at restaurant",
    "payment_method": "card",
    "expense_date": "2024-01-15",
    "created_at": "2024-01-15T10:30:00.000000Z",
    "updated_at": "2024-01-15T10:30:00.000000Z"
  }
}
```

**Flutter Handling:**

8. ExpenseService parses JSON to Expense model
9. ExpenseProvider adds expense to local list
10. Provider calls `notifyListeners()`
11. UI automatically updates
12. Expense cached locally
13. Success message shown
14. Bottom sheet closes

---

## 🔒 Error Handling Strategy

### 401 Unauthorized

**Scenario**: Token expired or invalid

**Laravel**:
```json
{
  "message": "Unauthenticated."
}
```

**Flutter Handling**:
```dart
on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    await deleteToken(); // Clear storage
    // Navigate to login screen
  }
}
```

### 403 Forbidden

**Scenario**: User trying to access another user's data

**Laravel**:
```php
if ($expense->user_id !== $request->user()->id) {
    return response()->json(['message' => 'Unauthorized'], 403);
}
```

**Flutter Handling**:
```dart
if (e.response?.statusCode == 403) {
  showErrorMessage('Access denied');
}
```

### 422 Validation Error

**Scenario**: Invalid input data

**Laravel**:
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "amount": ["The amount must be at least 0.01."],
    "email": ["The email has already been taken."]
  }
}
```

**Flutter Handling**:
```dart
if (e.response?.statusCode == 422) {
  final errors = e.response?.data['errors'];
  // Show field-specific errors in form
}
```

### 500 Server Error

**Scenario**: Laravel server error

**Flutter Handling**:
```dart
if (e.response?.statusCode == 500) {
  showErrorMessage('Server error. Please try again later.');
  debugPrint('Server error: ${e.response?.data}');
}
```

### Network Error (No Internet)

**Scenario**: Device offline

**Flutter Handling**:
```dart
on DioException catch (e) {
  if (e.type == DioExceptionType.connectionError) {
    // Load from cache
    return await _getCachedExpenses();
  }
}
```

---

## 🚀 Deployment Guide

### Flutter App Deployment

#### Android

1. **Configure App Signing**:
```bash
# Generate keystore
keytool -genkey -v -keystore ~/maticlens.jks -keyalg RSA -keysize 2048 -validity 10000 -alias maticlens
```

2. **Update `android/key.properties`**:
```properties
storePassword=your_password
keyPassword=your_password
keyAlias=maticlens
storeFile=/path/to/maticlens.jks
```

3. **Build APK**:
```bash
flutter build apk --release
```

4. **Build App Bundle** (for Play Store):
```bash
flutter build appbundle --release
```

#### iOS

1. **Configure Xcode**:
   - Open `ios/Runner.xcworkspace`
   - Set Team & Bundle ID
   - Configure signing

2. **Build**:
```bash
flutter build ios --release
```

3. **Archive in Xcode** for App Store submission

### Laravel Backend Deployment

#### Option 1: Laravel Forge

1. Connect server (DigitalOcean, AWS, etc.)
2. Create new site
3. Deploy from Git repository
4. Configure environment variables
5. Enable SSL certificate

#### Option 2: Manual (Ubuntu Server)

1. **Install Requirements**:
```bash
sudo apt update
sudo apt install php8.2 php8.2-fpm php8.2-mysql nginx mysql-server
```

2. **Clone Repository**:
```bash
git clone https://github.com/yourusername/maticlens-backend.git
cd maticlens-backend
```

3. **Install Dependencies**:
```bash
composer install --optimize-autoloader --no-dev
```

4. **Configure Environment**:
```bash
cp .env.example .env
php artisan key:generate
```

Edit `.env`:
```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.yoursite.com
DB_DATABASE=maticlens
DB_USERNAME=your_db_user
DB_PASSWORD=your_db_password
```

5. **Run Migrations**:
```bash
php artisan migrate --force
```

6. **Optimize**:
```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

7. **Configure Nginx**:
```nginx
server {
    listen 80;
    server_name api.yoursite.com;
    root /var/www/maticlens-backend/public;

    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

8. **Enable SSL** (Let's Encrypt):
```bash
sudo certbot --nginx -d api.yoursite.com
```

### Update Flutter App with Production API

Edit `lib/constants/api_constants.dart`:
```dart
class ApiConstants {
  static const baseUrl = 'https://api.yoursite.com/api';
  // ... rest of constants
}
```

Rebuild app:
```bash
flutter build apk --release
```

---

## 🧪 Testing Guide

### Test with Postman

1. **Import Collection**:
   - Create new collection "MaticLens API"
   - Set base URL variable: `{{baseUrl}}` = `http://localhost:8000/api`

2. **Register**:
```http
POST {{baseUrl}}/register
Body:
{
  "name": "Test User",
  "email": "test@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```
Save token from response.

3. **Set Authorization**:
   - Add to collection: Authorization → Bearer Token
   - Use saved token

4. **Test Endpoints**:
   - GET `/expenses`
   - POST `/expenses`
   - PUT `/expenses/1`
   - DELETE `/expenses/1`
   - POST `/budgets`
   - GET `/budgets`

### Test Flutter App

1. **Run on Emulator**:
```bash
flutter run
```

2. **Test Flow**:
   - Register new account
   - Add 5-10 expenses
   - Set budgets for categories
   - Check dashboard charts
   - Apply filters on expenses screen
   - Test logout and login

3. **Test Offline**:
   - Turn off internet
   - App should show cached expenses
   - Try to add expense (should fail gracefully)
   - Turn on internet
   - Refresh to sync

---

## 📊 Data Flow Example: Dashboard Screen

### Complete Flow

1. **App Startup**:
```
SplashScreen loads
    ↓
AuthProvider.checkAuthStatus()
    ↓
Token found in secure storage
    ↓
GET /api/user to verify token
    ↓
User authenticated → MainNavigation
```

2. **Dashboard Loads**:
```
MainNavigation initState()
    ↓
ExpenseProvider.loadExpenses()
    ↓
GET /api/expenses
    ↓
Laravel returns all user expenses
    ↓
Expenses cached locally
    ↓
BudgetProvider.loadBudgets()
    ↓
GET /api/budgets?month=1&year=2024
    ↓
Budgets loaded
    ↓
UI renders with data
```

3. **Dashboard Display**:
```
DashboardScreen builds
    ↓
context.watch<ExpenseProvider>()
    ↓
Calculate this month's expenses
    ↓
Generate category totals
    ↓
Render PieChart (fl_chart)
    ↓
Show recent transactions
    ↓
Display budget progress bars
```

4. **User Adds Expense**:
```
User taps Add button
    ↓
AddExpenseSheet modal shown
    ↓
User submits form
    ↓
POST /api/expenses
    ↓
Expense created in database
    ↓
Response parsed to Expense model
    ↓
ExpenseProvider adds to list
    ↓
notifyListeners() called
    ↓
Dashboard auto-updates
    ↓
Chart recalculates
    ↓
New expense appears in list
```

---

## 🎨 Customization Guide

### Change Primary Color

**Flutter** - Edit `lib/theme.dart`:
```dart
class LightModeColors {
  static const lightPrimary = Color(0xFF6366F1); // Change to Indigo
  // ... update other related colors
}
```

**Rebuild app**:
```bash
flutter run
```

### Add New Expense Category

1. **Flutter** - Edit `lib/constants/categories.dart`:
```dart
static const gymFitness = 'Gym & Fitness';

static const List<String> all = [
  // ... existing categories
  gymFitness,
];

static IconData getIcon(String category) {
  switch (category) {
    // ... existing cases
    case gymFitness:
      return FluentIcons.dumbbell_24_regular;
  }
}
```

2. **No backend changes needed** - categories are strings

### Add New Payment Method

1. **Flutter** - Edit `lib/constants/categories.dart`:
```dart
static const crypto = 'crypto';

static const List<String> all = [cash, card, bankTransfer, crypto];
```

2. **Laravel** - Update validation in `ExpenseController.php`:
```php
'payment_method' => 'required|string|in:cash,card,bank_transfer,crypto',
```

---

## 🐛 Common Issues & Solutions

### Issue: "Connection refused" on Android Emulator

**Solution**: Use `10.0.2.2` instead of `localhost`:
```dart
static const baseUrl = 'http://10.0.2.2:8000/api';
```

### Issue: CORS errors

**Solution**: Check `config/cors.php` in Laravel:
```php
'allowed_origins' => ['*'],
'allowed_headers' => ['*'],
```

### Issue: Token not persisting

**Solution**: Check secure storage permissions in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### Issue: Charts not rendering

**Solution**: Ensure `fl_chart` package is added and data is not empty:
```dart
if (categoryTotals.isNotEmpty) {
  CategoryChart(categoryTotals: categoryTotals)
}
```

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Laravel Documentation](https://laravel.com/docs)
- [Laravel Sanctum](https://laravel.com/docs/sanctum)
- [Provider Package](https://pub.dev/packages/provider)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [FL Chart](https://pub.dev/packages/fl_chart)

---

**🎉 Your MaticLens app is now complete and ready for production!**

Both frontend and backend are fully integrated and ready to deploy. Follow the deployment guides above to launch your app.
