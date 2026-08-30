import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/app_user.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  try {
    return ref.watch(authServiceProvider).authStateChanges;
  } on FirebaseException {
    return const Stream<User?>.empty();
  }
});

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _hydrate();
  }

  final AuthService _authService;

  /// Runs once at startup. If Firebase already has a signed-in user
  /// (persisted session from a previous app launch), load their profile.
  /// Otherwise resolve immediately to "not logged in" so the login/register
  /// buttons actually render instead of spinning forever.
  Future<void> _hydrate() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        state = const AsyncValue.data(null);
        return;
      }
      state = await AsyncValue.guard(() => _fetchOrCreateProfile(firebaseUser));
    } on FirebaseException catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<AppUser> _fetchOrCreateProfile(User firebaseUser) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (doc.exists && doc.data() != null) {
      return AppUser.fromJson({'uid': firebaseUser.uid, ...doc.data()!});
    }

    // Fallback: no Firestore doc yet (legacy account or race condition)
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      userType: 'customer',
      createdAt: DateTime.now(),
      lastSignIn: DateTime.now(),
      isVerified: firebaseUser.emailVerified,
      favorites: const [],
    );
  }

  /// Register — creates Firebase Auth user + saves full profile to Firestore
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String userType,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await _authService.registerWithEmail(
        email: email,
        password: password,
      );
      await _authService.updateUserProfile(displayName: displayName);

      final user = AppUser(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        userType: userType,
        createdAt: DateTime.now(),
        lastSignIn: DateTime.now(),
        isVerified: false,
        favorites: const [],
      );

      // Save to Firestore so userType persists across sessions
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(user.toJson());
      // Fire-and-forget: push-token registration must never block or
      // appear to hang the sign-up flow. See NotificationService.registerDevice.
      unawaited(NotificationService().registerDevice(user.uid));

      return user;
    });
  }

  /// Login — fetches userType from Firestore so business users see correct UI
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      final appUser = await _fetchOrCreateProfile(credential.user!);
      // Fire-and-forget — see registerDevice() doc comment: this must
      // never gate login completing.
      unawaited(NotificationService().registerDevice(appUser.uid));
      return appUser;
    });
  }

  Future<void> loginWithGoogle({String userType = 'customer'}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await _authService.signInWithGoogle();
      final user = credential.user!;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return AppUser.fromJson({'uid': user.uid, ...doc.data()!});
      }

      final appUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        userType: userType,
        createdAt: DateTime.now(),
        lastSignIn: DateTime.now(),
        isVerified: user.emailVerified,
        favorites: const [],
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(appUser.toJson());
      // Fire-and-forget — see registerDevice() doc comment.
      unawaited(NotificationService().registerDevice(user.uid));

      return appUser;
    });
  }

  Future<void> logout() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) await NotificationService().unregisterDevice(userId);
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> resetPassword(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  /// Add or remove a deal from the current user's favorites,
  /// keeping both Firestore and local state in sync.
  Future<void> toggleFavorite(String dealId) async {
    final currentUser = state.asData?.value;
    if (currentUser == null) return;

    final isFavorite = currentUser.favorites.contains(dealId);
    final updatedFavorites = isFavorite
        ? (List<String>.from(currentUser.favorites)..remove(dealId))
        : (List<String>.from(currentUser.favorites)..add(dealId));

    // Optimistically update local state so the UI reacts instantly.
    state = AsyncValue.data(currentUser.copyWith(favorites: updatedFavorites));

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'favorites': isFavorite
            ? FieldValue.arrayRemove([dealId])
            : FieldValue.arrayUnion([dealId]),
      });
    } on Object {
      // Roll back on failure
      state = AsyncValue.data(currentUser);
      rethrow;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>(
    (ref) => AuthNotifier(ref.watch(authServiceProvider)));

/// Whether the currently signed-in account is an active staff member of
/// some business (business_staff/{uid}.isActive == true) — separate from
/// owning a business (userType == 'restaurant'). Staff sign up as ordinary
/// customer accounts; a business owner grants them access afterward via
/// ManageStaffPage / BusinessStaffService.addStaff.
///
/// Lives here (not in router_config.dart, where it's also used) so that
/// both router_config.dart and profile_page.dart can depend on it without
/// a circular import between the two.
final isActiveBusinessStaffProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null) return Stream.value(false);
  return FirebaseFirestore.instance
      .collection('business_staff')
      .doc(user.uid)
      .snapshots()
      .map((snap) => snap.exists && snap.data()?['isActive'] == true);
});
