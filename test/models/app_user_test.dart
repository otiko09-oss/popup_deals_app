import 'package:flutter_test/flutter_test.dart';
import 'package:popup_deals_app/features/auth/data/models/app_user.dart';

AppUser _baseUser({bool? isAdmin}) => AppUser(
      uid: 'uid_123',
      email: 'test@example.com',
      userType: 'customer',
      createdAt: DateTime(2026, 1, 1),
      lastSignIn: DateTime(2026, 1, 2),
      isVerified: true,
      favorites: const ['deal_1'],
      isAdmin: isAdmin ?? false,
    );

void main() {
  group('AppUser.isAdmin', () {
    test('defaults to false when not provided', () {
      final user = _baseUser();
      expect(user.isAdmin, isFalse);
    });

    test('fromJson defaults to false when key is missing entirely', () {
      final json = _baseUser().toJson()..remove('isAdmin');
      final user = AppUser.fromJson(json);
      expect(user.isAdmin, isFalse);
    });

    test('round-trips true through toJson/fromJson', () {
      final admin = _baseUser(isAdmin: true);
      final restored = AppUser.fromJson(admin.toJson());
      expect(restored.isAdmin, isTrue);
    });

    test('copyWith without isAdmin preserves the existing value', () {
      final admin = _baseUser(isAdmin: true);
      final copy = admin.copyWith(displayName: 'New Name');
      expect(copy.isAdmin, isTrue);
    });

    test('copyWith can explicitly change isAdmin', () {
      final user = _baseUser(isAdmin: false);
      final promoted = user.copyWith(isAdmin: true);
      expect(promoted.isAdmin, isTrue);
      // Original instance is untouched (immutability).
      expect(user.isAdmin, isFalse);
    });
  });
}
