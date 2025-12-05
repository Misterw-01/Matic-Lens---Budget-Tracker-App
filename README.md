# maticlens

# 💰 MaticLens - Intelligent Expense Tracker

A complete end-to-end mobile expense tracking application with Flutter frontend and Laravel backend.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Laravel](https://img.shields.io/badge/Laravel-11-FF2D20?logo=laravel)

## ✨ Features

### 📱 Mobile App (Flutter)
- ✅ User registration & authentication
- ✅ Secure token storage
- ✅ Add, edit, delete expenses
- ✅ Categorize expenses (10 categories)
- ✅ Multiple payment methods (Cash, Card, Bank Transfer)
- ✅ Monthly budget tracking
- ✅ Visual progress indicators
- ✅ Interactive pie charts
- ✅ Advanced filtering (category, payment method, date range)
- ✅ Local caching for offline support
- ✅ Pull-to-refresh
- ✅ Modern, minimalist UI
- ✅ Dark mode support

### 🔧 Backend API (Laravel)
- ✅ RESTful JSON API
- ✅ Laravel Sanctum authentication
- ✅ Token-based auth
- ✅ CRUD operations for expenses
- ✅ CRUD operations for budgets
- ✅ Input validation
- ✅ User authorization
- ✅ Database indexing
- ✅ CORS configured

## 🎨 Design

**Sophisticated Monochrome Theme**
- Pure white/deep charcoal backgrounds
- Teal accent color (#14B8A6)
- Flat design with border-based definition
- Inter font family
- Fluent UI icons
- Generous spacing
- Professional finance app aesthetic

## 🏗️ Tech Stack

### Frontend
- **Framework**: Flutter 3.x
- **State Management**: Provider
- **HTTP Client**: Dio
- **Secure Storage**: flutter_secure_storage
- **Charts**: fl_chart
- **Icons**: fluentui_system_icons
- **Local Storage**: shared_preferences
- **Date Formatting**: intl

### Backend
- **Framework**: Laravel 11
- **Authentication**: Laravel Sanctum
- **Database**: MySQL/PostgreSQL
- **API**: RESTful JSON

## 📁 Project Structure

```
lib/
├── constants/          # API endpoints, categories
├── models/            # Data models (User, Expense, Budget)
├── services/          # API service classes
├── providers/         # State management
├── screens/           # UI screens
├── widgets/           # Reusable widgets
├── main.dart          # App entry point
└── theme.dart         # Design system

Complete Laravel backend code in: LARAVEL_BACKEND.md
Complete integration guide in: INTEGRATION_GUIDE.md
Architecture details in: architecture.md
```

## 🚀 Quick Start

### Flutter App

1. **Install dependencies**:
```bash
flutter pub get
```

2. **Run the app**:
```bash
flutter run
```

3. **Build for release**:
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Laravel Backend

1. **Create project**:
```bash
composer create-project laravel/laravel maticlens-backend
cd maticlens-backend
```

2. **Install Sanctum**:
```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
```

3. **Configure database** in `.env`:
```env
DB_DATABASE=maticlens
DB_USERNAME=root
DB_PASSWORD=your_password
```

4. **Copy models, controllers, migrations** from `LARAVEL_BACKEND.md`

5. **Run migrations**:
```bash
php artisan migrate
```

6. **Start server**:
```bash
php artisan serve
```

## 🔗 API Endpoints

### Authentication
- `POST /api/register` - Register new user
- `POST /api/login` - Login user
- `POST /api/logout` - Logout user
- `GET /api/user` - Get current user

### Expenses
- `GET /api/expenses` - Get all expenses (with filters)
- `POST /api/expenses` - Create expense
- `GET /api/expenses/{id}` - Get expense
- `PUT /api/expenses/{id}` - Update expense
- `DELETE /api/expenses/{id}` - Delete expense

### Budgets
- `GET /api/budgets` - Get budgets (with filters)
- `POST /api/budgets` - Create/update budget
- `GET /api/budgets/{id}` - Get budget
- `DELETE /api/budgets/{id}` - Delete budget

## 🔒 Authentication Flow

```
1. User registers/logs in
2. Laravel generates Sanctum token
3. Flutter stores token in secure storage
4. All API requests include: Authorization: Bearer {token}
5. Laravel validates token via auth:sanctum middleware
6. On 401: Flutter clears token and redirects to login
```

## 📊 Data Models

### User
```dart
- id: String
- name: String
- email: String
- created_at: DateTime
- updated_at: DateTime
```

### Expense
```dart
- id: String
- user_id: String
- category: String
- amount: double
- note: String
- payment_method: String
- expense_date: DateTime
- created_at: DateTime
- updated_at: DateTime
```

### Budget
```dart
- id: String
- user_id: String
- category: String
- limit_amount: double
- month: int (1-12)
- year: int
- created_at: DateTime
- updated_at: DateTime
```

## 🎯 Expense Categories

- 🍕 Food & Dining
- 🚗 Transportation
- 🛍️ Shopping
- 🎬 Entertainment
- 📄 Bills & Utilities
- 🏥 Healthcare
- 📚 Education
- ✈️ Travel
- 💅 Personal Care
- 📦 Other

## 💳 Payment Methods

- 💵 Cash
- 💳 Card
- 🏦 Bank Transfer

## 🌐 Configuration

### Update API URL (Flutter)

Edit `lib/constants/api_constants.dart`:

```dart
// Local development (Android Emulator)
static const baseUrl = 'http://10.0.2.2:8000/api';

// Local development (iOS Simulator)
static const baseUrl = 'http://localhost:8000/api';

// Production
static const baseUrl = 'https://api.yoursite.com/api';
```

## 🧪 Testing

### Test Backend with Postman

1. Register user → Save token
2. Set Authorization: Bearer {token}
3. Test all endpoints

### Test Flutter App

1. Register new account
2. Add multiple expenses
3. Set budgets
4. View dashboard charts
5. Test filters
6. Test offline mode

## 📦 Dependencies

### Flutter
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  dio: ^5.0.0
  flutter_secure_storage: ^9.2.4
  fl_chart: 0.68.0
  fluentui_system_icons: ^1.0.0
  shared_preferences: ^2.0.0
  intl: 0.20.2
  google_fonts: ^6.1.0
```

### Laravel
```bash
composer require laravel/sanctum
```

## 🚢 Deployment

### Flutter
- **Android**: Build APK/App Bundle
- **iOS**: Archive in Xcode
- **Stores**: Google Play, App Store

### Laravel
- **Hosting**: Laravel Forge, DigitalOcean, AWS
- **SSL**: Let's Encrypt (Certbot)
- **Server**: Nginx with PHP-FPM

See `INTEGRATION_GUIDE.md` for detailed deployment instructions.

## 📱 Screenshots

The app features:
- Clean login/register screens
- Dashboard with pie charts
- Expense list with filters
- Budget management with progress bars
- Modern profile screen
- Smooth bottom sheet modals

## 🐛 Troubleshooting

**Connection refused on Android?**
- Use `10.0.2.2` instead of `localhost`

**CORS errors?**
- Check Laravel `config/cors.php`

**Token not saving?**
- Check Android permissions

**Charts not showing?**
- Ensure data is not empty

See `INTEGRATION_GUIDE.md` for more solutions.

## 📚 Documentation

- `LARAVEL_BACKEND.md` - Complete Laravel backend code
- `INTEGRATION_GUIDE.md` - Integration & deployment guide
- `architecture.md` - System architecture overview

## 🔐 Security

- ✅ Password hashing (bcrypt)
- ✅ Token-based authentication
- ✅ Secure token storage
- ✅ Input validation
- ✅ User authorization
- ✅ HTTPS in production
- ✅ Environment variables

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📄 License

This project is open source and available under the MIT License.

## 👨‍💻 Author

Built with ❤️ using Flutter & Laravel

## 🙏 Acknowledgments

- Flutter team for amazing framework
- Laravel team for robust backend
- Fluent UI for beautiful icons
- FL Chart for charting library

---

## 🎯 Next Steps

1. ✅ Clone repository
2. ✅ Set up Laravel backend (see `LARAVEL_BACKEND.md`)
3. ✅ Update API URL in Flutter app
4. ✅ Run `flutter pub get`
5. ✅ Test on emulator
6. ✅ Deploy to production

**Need help?** Check `INTEGRATION_GUIDE.md` for complete setup instructions!

---

**MaticLens** - Track smarter, spend better. 💰📊

