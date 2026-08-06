import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, Logger? logger})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _logger = logger ?? Logger();
  final FirebaseAuth _firebaseAuth;
  final Logger _logger;

  /// Get current user
  User? get currentUser {
    try {
      return _firebaseAuth.currentUser;
    } on FirebaseException catch (e) {
      if (e.code == 'no-app') {
        return null;
      }
      rethrow;
    }
  }

  /// Get user UID
  String? get uid => currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Register with email and password
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Attempting to register user with email: $email');
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _logger.i('User registered successfully: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error during registration: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Attempting to sign in user with email: $email');
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _logger.i('User signed in successfully: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error during sign in: $e');
      rethrow;
    }
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      _logger.i('Attempting Google sign in');
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'aborted-by-user',
          message: 'Google sign in was cancelled',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      _logger.i('Google sign in successful: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error during Google sign in: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _logger.i('Signing out user');
      await _firebaseAuth.signOut();
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Error during sign out: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _logger.i('Sending password reset email to: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error sending password reset email: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      _logger.i('Updating user profile');
      final user = currentUser;
      if (user == null) {
        _logger.w('No authenticated user found');
        return;
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      _logger.i('User profile updated successfully');
    } on Object catch (e) {
      _logger.e('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      _logger.i('Deleting user account: ${currentUser?.uid}');
      await currentUser?.delete();
      _logger.i('User account deleted successfully');
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error deleting account: $e');
      rethrow;
    }
  }
}
