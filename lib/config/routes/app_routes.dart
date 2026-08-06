class AppRoutes {
  // Splash
  static const String splash = '/';

  // Auth Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main Shell Routes (with bottom nav)
  static const String home = '/home';
  static const String feed = '/feed';
  static const String orders = '/orders';
  static const String profile = '/profile';

  // Deal Routes (full screen, no shell)
  static const String deals = '/deals';
  static const String dealDetail = '/deals/detail';
  static const String favorites = '/favorites';

  // Business Shell Routes (with bottom nav)
  static const String businessDeals = '/business/deals';
  static const String createDeal = '/business/create-deal';
  static const String editDeal = '/business/edit-deal';
  static const String businessOrders = '/business/orders';
  static const String analytics = '/business/analytics';

  // Settings Routes
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String helpSupport = '/help-support';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';

  // Business onboarding & subscription
  static const String businessOnboarding = '/business/onboarding';
  static const String subscription = '/business/subscription';

  // QR Redemption
  static const String qrScanner = '/business/scan-qr';

  // Admin
  static const String admin = '/admin';
}
