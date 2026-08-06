# Popup Deals App 🍔

A production-ready Flutter application for discovering and redeeming food deals and marketplace offers. Built with clean architecture, Firebase backend, and Riverpod state management.

## 🎯 Features

- **Authentication**: Email/password registration and login with Firebase Auth
- **Deal Discovery**: Browse, search, and filter deals by category
- **Favorites**: Save favorite deals for later
- **Deal Details**: Comprehensive deal information with restaurant details
- **User Flows**: Separate navigation for customers and restaurants
- **Modern UI**: Beautiful, responsive Material Design 3 theme
- **Real-time Data**: Firestore integration for real-time deal updates
- **Push Notifications**: Firebase Cloud Messaging support

## 🏗️ Architecture

```
lib/
├── config/              # Configuration files
│   ├── firebase/        # Firebase setup and options
│   └── routes/          # GoRouter configuration
├── core/                # Core functionality
│   ├── constants/       # App-wide constants
│   ├── services/        # Base services (Auth, Firestore, Storage)
│   ├── theme/           # App theming
│   └── utils/           # Utilities and helpers
├── features/            # Feature modules
│   ├── auth/            # Authentication feature
│   │   ├── data/
│   │   │   └── models/
│   │   └── presentation/
│   │       ├── pages/
│   │       └── providers/
│   ├── home/            # Home feature
│   │   └── presentation/
│   │       ├── pages/
│   │       └── providers/
│   └── deals/           # Deals feature
│       ├── data/
│       │   └── models/
│       └── presentation/
│           ├── pages/
│           └── providers/
└── main.dart
```

## 🚀 Getting Started

### Prerequisites

- Flutter 3.10.0 or higher
- Dart 3.0.0 or higher
- Firebase account

### Installation

1. **Clone and setup**
   ```bash
   cd popup_deals_app
   flutter pub get
   ```

2. **Configure Firebase**
   - Update `lib/config/firebase/firebase_options.dart` with your Firebase credentials
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files

3. **Run the app**
   ```bash
   flutter run
   ```

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Authentication |
| `cloud_firestore` | Real-time database |
| `firebase_storage` | File storage |
| `firebase_messaging` | Push notifications |
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `google_fonts` | Typography |
| `dio` | HTTP client |

## 🔐 Firebase Setup

### Collections Schema

**users**
```json
{
  "uid": "user_id",
  "email": "user@example.com",
  "displayName": "User Name",
  "photoUrl": "https://...",
  "userType": "customer", // or "restaurant"
  "createdAt": "timestamp",
  "lastSignIn": "timestamp",
  "isVerified": false,
  "favorites": ["deal_id_1", "deal_id_2"]
}
```

**deals**
```json
{
  "id": "deal_id",
  "title": "50% off Pizza",
  "description": "Delicious pizza offer",
  "imageUrl": "https://...",
  "originalPrice": 20.00,
  "discountedPrice": 10.00,
  "discountPercentage": 50,
  "category": "Pizza",
  "restaurant": "Pizza Hub",
  "restaurantId": "restaurant_id",
  "expiresAt": "timestamp",
  "createdAt": "timestamp",
  "isActive": true,
  "likes": 150,
  "redeemed": 42,
  "tags": ["pizza", "italian"],
  "latitude": 40.7128,
  "longitude": -74.0060
}
```

## 🎨 Theme

The app features a modern food/marketplace design with:

- **Primary Color**: Vibrant Orange (#FF6B35)
- **Secondary Color**: Deep Blue (#004E89)
- **Accent Color**: Green (#1DB959) for deals
- **Typography**: Google Fonts (Inter for body, system fonts for display)
- **Spacing System**: Consistent 4-unit based spacing
- **Border Radius**: Rounded corners for modern feel

## 🔄 State Management with Riverpod

Key providers:

- `authProvider`: Authentication state
- `dealsProvider`: All active deals stream
- `dealsByCategoryProvider`: Filtered deals by category
- `favoriteDealsProvider`: User's favorite deals
- `dealProvider`: Single deal details

## 🧭 Navigation with GoRouter

Routes:

| Route | Description |
|-------|-------------|
| `/login` | Login page |
| `/register` | Registration page |
| `/home` | Home/dashboard |
| `/deals` | All deals listing |
| `/deals/detail/:id` | Deal details |
| `/profile` | User profile |
| `/favorites` | Saved deals |
| `/restaurant/dashboard` | Restaurant dashboard |

## 📝 Services

### AuthService
Handles all authentication operations:
- Register with email/password
- Sign in/out
- Password reset
- Profile updates

### FirestoreService
Firestore database operations:
- CRUD operations
- Real-time streams
- Search functionality
- Batch and transaction writes

### StorageService
Firebase Storage operations:
- File uploads
- File downloads
- URL generation
- File deletion

## 🧪 Error Handling

The app includes comprehensive error handling:
- Firebase Auth exception mapping
- Network error handling
- User-friendly error messages
- Logging with Logger package

## 📱 Screen-Responsive Design

Uses `flutter_screenutil` for responsive design:
- Adapts to different screen sizes
- Maintains consistent spacing and sizing
- Works on phones, tablets, and web

## 🔌 Extending the App

### Adding a New Feature

1. Create feature folder in `lib/features/`
2. Add `data/`, `presentation/` subfolder structure
3. Create models in `data/models/`
4. Create pages in `presentation/pages/`
5. Create providers in `presentation/providers/`
6. Add routes in `config/routes/`

### Adding a New Service

1. Create service file in `lib/core/services/`
2. Register in `service_locator.dart`
3. Create provider in relevant feature

## 🚀 Deployment

### Android
```bash
flutter build apk --split-per-abi
# or for release
flutter build appbundle
```

### iOS
```bash
flutter build ios --release
```

## 📚 Best Practices Implemented

✅ Clean Architecture with separation of concerns
✅ State management with Riverpod
✅ Dependency injection with GetIt
✅ Type-safe routing with GoRouter
✅ Comprehensive error handling
✅ Logging for debugging
✅ Firebase security best practices
✅ Responsive UI design
✅ Code organization by feature
✅ Constants and configuration management

## 🤝 Contributing

1. Follow Flutter best practices
2. Use meaningful commit messages
3. Test features before submitting
4. Keep code organized by feature

## 📄 License

This project is private and proprietary.

## 📧 Support

For issues and questions, contact the development team.

---

**Built for Scale** 🚀 - Ready for production deployment and scaling
