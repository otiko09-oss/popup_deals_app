import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/auth/data/models/app_user.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/business/presentation/pages/business_deals_page.dart';
import '../../features/business/presentation/pages/business_onboarding_page.dart';
import '../../features/business/presentation/pages/manage_staff_page.dart';
import '../../features/business/presentation/screens/add_deal_screen.dart';
import '../../features/business/presentation/screens/analytics_screen.dart';
import '../../features/business/presentation/screens/edit_deal_screen.dart';
import '../../features/deals/presentation/pages/deal_detail_page.dart';
import '../../features/deals/presentation/pages/favorites_page.dart';
import '../../features/deals/presentation/pages/popup_deals_feed_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/main_shell.dart';
import '../../features/home/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/splash_screen.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/help_support_page.dart';
import '../../features/profile/presentation/pages/privacy_policy_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/terms_of_service_page.dart';
import '../../features/redemption/presentation/pages/qr_scanner_entry_point.dart';
import '../../features/subscription/presentation/pages/subscription_page.dart';
import 'app_routes.dart';

// Routes reachable without being logged in.
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
};

// Routes only a 'restaurant' account should reach.
const _businessOnlyRoutes = {
  AppRoutes.businessDeals,
  AppRoutes.createDeal,
  AppRoutes.editDeal,
  AppRoutes.businessOrders,
  AppRoutes.analytics,
  AppRoutes.businessOnboarding,
  AppRoutes.subscription,
  AppRoutes.qrScanner,
  AppRoutes.manageStaff,
};

/// Whether the currently signed-in 'restaurant' user has actually completed
/// business onboarding — i.e. has a businesses/{uid} Firestore doc.
///
/// This exists because the redirect logic used to only check
/// `user.userType == 'restaurant'` and send those accounts straight to the
/// business dashboard, with nothing checking whether business onboarding
/// (BusinessOnboardingPage, which is what actually creates the
/// businesses/{uid} doc) had ever been completed. Anyone who backed out of
/// or was interrupted during onboarding — including by something as
/// ordinary as a hot restart — got permanently routed to business screens
/// with no underlying business record: invisible to admins in the
/// Businesses tab (nothing to list) and hitting permission-denied on every
/// deal creation (isApprovedBusiness() has nothing to check), with no way
/// back to onboarding through normal navigation.
final businessProfileExistsProvider = StreamProvider<bool?>((ref) {
  final user = ref.watch(authProvider).asData?.value;
  if (user == null || user.userType != 'restaurant') {
    return Stream.value(null); // not a restaurant account — not applicable
  }
  return FirebaseFirestore.instance
      .collection('businesses')
      .doc(user.uid)
      .snapshots()
      .map((snap) => snap.exists);
});

String? resolveAuthRedirect({
  required String path,
  required AsyncValue<AppUser?> authState,
  bool? businessProfileExists,
  bool isActiveBusinessStaff = false,
  bool isAdmin = false,
}) {
  if (authState.isLoading) {
    return path == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final user = authState.asData?.value;
  final loggedIn = user != null;

  if (!loggedIn && !_publicRoutes.contains(path)) {
    return AppRoutes.login;
  }

  if (loggedIn && _publicRoutes.contains(path)) {
    if (user.userType == 'restaurant') {
      return businessProfileExists == true
          ? AppRoutes.businessDeals
          : AppRoutes.businessOnboarding;
    }
    return AppRoutes.home;
  }

  if (loggedIn &&
      user.userType == 'restaurant' &&
      path != AppRoutes.businessOnboarding &&
      businessProfileExists != true) {
    return AppRoutes.businessOnboarding;
  }

  if (path == AppRoutes.admin && !isAdmin) {
    return loggedIn ? AppRoutes.home : AppRoutes.login;
  }

  if (loggedIn &&
      _businessOnlyRoutes.contains(path) &&
      user.userType != 'restaurant' &&
      !(path == AppRoutes.qrScanner && isActiveBusinessStaff)) {
    return AppRoutes.home;
  }

  if (path == AppRoutes.splash && !loggedIn) {
    return null;
  }

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // IMPORTANT: this used to be `final authState = ref.watch(authProvider);`
  // directly inside this Provider<GoRouter> builder. That meant every single
  // authProvider state change (loading -> data, loading -> error, etc. — so
  // every login/register/logout attempt) rebuilt this whole provider and
  // therefore constructed a BRAND NEW GoRouter object. Swapping in a new
  // GoRouter resets it to `initialLocation: AppRoutes.splash` and gives
  // SplashScreen a fresh widget instance with fresh ref.listen()s — which
  // only fire on *future* changes, not the state change that just already
  // happened. Net effect: tap "Sign In", the auth state settles (even to an
  // error) before the new SplashScreen's listeners are attached, and the
  // app is left sitting on a spinning splash screen forever, regardless of
  // whether sign-in actually succeeded or failed.
  //
  // Fix: build the GoRouter exactly once and use GoRouter's own
  // `refreshListenable` to tell it "re-run redirect", instead of Riverpod
  // recreating the router. `redirect` below reads the current auth state
  // fresh (ref.read) each time it's invoked rather than closing over a
  // value captured at build time.
  final notifier = _AuthRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) async {
      final path = state.matchedLocation;
      final authState = ref.read(authProvider);
      final businessProfileExists =
          ref.read(businessProfileExistsProvider).asData?.value;
      final isActiveBusinessStaff =
          ref.read(isActiveBusinessStaffProvider).asData?.value ?? false;

      if (authState.isLoading) {
        return path == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final user = authState.asData?.value;
      final loggedIn = user != null;

      if (path == AppRoutes.splash && !loggedIn) {
        final prefs = await SharedPreferences.getInstance();
        final seenOnboarding = prefs.getBool('onboardingSeen') ?? false;
        return seenOnboarding ? AppRoutes.login : AppRoutes.onboarding;
      }

      return resolveAuthRedirect(
        path: path,
        authState: authState,
        businessProfileExists: businessProfileExists,
        isActiveBusinessStaff: isActiveBusinessStaff,
        isAdmin: user?.isAdmin ?? false,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
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
        builder: (context, state) => const QrScannerEntryPoint(),
      ),
      GoRoute(
        path: AppRoutes.manageStaff,
        name: 'manageStaff',
        builder: (context, state) => const ManageStaffPage(),
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

/// Bridges Riverpod's authProvider to GoRouter's `refreshListenable`.
///
/// This lets GoRouter re-run its `redirect` callback whenever auth state
/// changes, WITHOUT Riverpod tearing down and rebuilding the GoRouter
/// instance itself (see the long comment on routerProvider above for why
/// that was causing sign-in to appear to hang forever on the splash screen).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue>(authProvider, (_, __) => notifyListeners());
    ref.listen<AsyncValue<bool?>>(
      businessProfileExistsProvider,
      (_, __) => notifyListeners(),
    );
    ref.listen<AsyncValue<bool>>(
      isActiveBusinessStaffProvider,
      (_, __) => notifyListeners(),
    );
  }
}
