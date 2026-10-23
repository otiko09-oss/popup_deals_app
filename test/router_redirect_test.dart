import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_deals_app/config/routes/app_routes.dart';
import 'package:popup_deals_app/config/routes/router_config.dart';
import 'package:popup_deals_app/features/auth/data/models/app_user.dart';

void main() {
  group('resolveAuthRedirect', () {
    test('routes a logged-in customer away from login to the home screen', () {
      final user = AppUser(
        uid: 'uid-1',
        email: 'user@example.com',
        userType: 'customer',
        createdAt: DateTime.now(),
        lastSignIn: DateTime.now(),
        isVerified: true,
        favorites: const [],
      );

      final result = resolveAuthRedirect(
        path: AppRoutes.login,
        authState: AsyncValue.data(user),
      );

      expect(result, AppRoutes.home);
    });

    test('routes an un-onboarded restaurant away from login to onboarding', () {
      final user = AppUser(
        uid: 'biz-1',
        email: 'biz@example.com',
        userType: 'restaurant',
        createdAt: DateTime.now(),
        lastSignIn: DateTime.now(),
        isVerified: true,
        favorites: const [],
      );

      final result = resolveAuthRedirect(
        path: AppRoutes.login,
        authState: AsyncValue.data(user),
      );

      expect(result, AppRoutes.businessOnboarding);
    });
  });
}
