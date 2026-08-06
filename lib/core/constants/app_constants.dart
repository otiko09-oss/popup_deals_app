// Firestore Collections
class FirestoreCollections {
  static const String users = 'users';
  static const String deals = 'deals';
  static const String restaurants = 'restaurants';
  static const String orders = 'orders';
  static const String reviews = 'reviews';
  static const String favorites = 'favorites';
  static const String notifications = 'notifications';
}

// Deal Status
class DealStatus {
  static const String active = 'active';
  static const String expired = 'expired';
  static const String paused = 'paused';
  static const String archived = 'archived';
}

// User Types
class UserType {
  static const String customer = 'customer';
  static const String restaurant = 'restaurant';
  static const String admin = 'admin';
}

// API Endpoints (if using REST)
class ApiEndpoints {
  static const String baseUrl = 'https://api.popupdeals.app/v1';
  static const String deals = '/deals';
  static const String restaurants = '/restaurants';
  static const String users = '/users';
  static const String orders = '/orders';
}

// Error Messages
class ErrorMessages {
  static const String networkError = 'Network error. Please try again.';
  static const String serverError = 'Server error. Please try again later.';
  static const String invalidEmail = 'Invalid email address.';
  static const String weakPassword = 'Password must be at least 6 characters.';
  static const String userNotFound = 'User not found.';
  static const String wrongPassword = 'Incorrect password.';
  static const String userAlreadyExists = 'User already exists.';
  static const String unknownError = 'An unknown error occurred.';
}

// Success Messages
class SuccessMessages {
  static const String registrationSuccess = 'Registration successful!';
  static const String loginSuccess = 'Logged in successfully!';
  static const String logoutSuccess = 'Logged out successfully!';
  static const String dealSaved = 'Deal saved to favorites!';
  static const String dealRemoved = 'Deal removed from favorites!';
  static const String dealRedeemed = 'Redirecting to restaurant app...';
}
