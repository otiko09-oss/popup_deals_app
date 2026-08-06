import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/business/presentation/pages/business_deals_page.dart';
import '../../features/business/presentation/pages/business_onboarding_page.dart';
import '../../features/business/presentation/screens/add_deal_screen.dart';
import '../../features/business/presentation/screens/analytics_screen.dart';
import '../../features/business/presentation/screens/edit_deal_screen.dart';
import '../../features/deals/presentation/pages/deal_detail_page.dart';
import '../../features/deals/presentation/pages/favorites_page.dart';
import '../../features/deals/presentation/pages/popup_deals_feed_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/main_shell.dart';
import '../../features/home/presentation/pages/splash_screen.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/help_support_page.dart';
import '../../features/profile/presentation/pages/privacy_policy_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/terms_of_service_page.dart';
import '../../features/redemption/presentation/pages/qr_scanner_page.dart';
import '../../features/subscription/presentation/pages/subscription_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '${AppRoutes.editDeal}/:id',
        name: 'editDeal',
        builder: (context, state) {
          final dealId = state.pathParameters['id']!;
          return EditDealScreen(dealId: dealId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.dealDetail}/:id',
        name: 'dealDetail',
        pageBuilder: (context, state) {
          final dealId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: DealDetailPage(dealId: dealId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.favorites,
        name: 'favorites',
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(
        path: AppRoutes.businessOnboarding,
        name: 'businessOnboarding',
        builder: (context, state) => const BusinessOnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        name: 'subscription',
        builder: (context, state) {
          final businessId =
              ref.read(authStateProvider).asData?.value?.uid ?? '';
          return SubscriptionPage(businessId: businessId);
        },
      ),
      GoRoute(
        path: AppRoutes.qrScanner,
        name: 'qrScanner',
        builder: (context, state) {
          final businessId =
              ref.read(authStateProvider).asData?.value?.uid ?? '';
          return QrScannerPage(businessId: businessId);
        },
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.helpSupport,
        name: 'helpSupport',
        builder: (context, state) => const HelpSupportPage(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        name: 'privacyPolicy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppRoutes.termsOfService,
        name: 'termsOfService',
        builder: (context, state) => const TermsOfServicePage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.feed,
            name: 'feed',
            builder: (context, state) => const PopupDealsFeedPage(),
          ),
          GoRoute(
            path: AppRoutes.orders,
            name: 'orders',
            builder: (context, state) => const OrdersPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.businessDeals,
            name: 'businessDeals',
            builder: (context, state) => const BusinessDealsPage(),
          ),
          GoRoute(
            path: AppRoutes.createDeal,
            name: 'createDeal',
            builder: (context, state) => const AddDealScreen(),
          ),
          GoRoute(
            path: AppRoutes.businessOrders,
            name: 'businessOrders',
            builder: (context, state) => const OrdersPage(),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Page not found',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
