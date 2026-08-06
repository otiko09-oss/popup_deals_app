import 'package:firebase_auth/firebase_auth.dart';

class AppException implements Exception {
  AppException({
    required this.message,
    this.code,
    this.originalException,
  });
  final String message;
  final String? code;
  final dynamic originalException;

  @override
  String toString() => message;
}

class AppExceptionHandler {
  static String handleException(dynamic exception) {
    if (exception is FirebaseAuthException) {
      return _handleFirebaseAuthException(exception);
    } else if (exception is AppException) {
      return exception.message;
    } else if (exception is Exception) {
      return exception.toString();
    } else {
      return 'An unknown error occurred';
    }
  }

  static String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }

  static AppException createException(
    String message, {
    String? code,
    dynamic originalException,
  }) =>
      AppException(
        message: message,
        code: code,
        originalException: originalException,
      );
}
