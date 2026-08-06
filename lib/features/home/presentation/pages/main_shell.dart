import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:popup_deals_app/config/routes/app_routes.dart';
import 'package:popup_deals_app/core/widgets/connectivity_banner.dart';
import 'package:popup_deals_app/features/auth/presentation/providers/auth_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Authentication error')),
      ),
      data: (user) {
        final appUser = ref.watch(authProvider).asData?.value;
        final isBusinessUser = appUser?.userType == 'restaurant';

        return Scaffold(
          body: ConnectivityBanner(child: child),
          bottomNavigationBar: isBusinessUser
              ? _BusinessBottomNav(context: context)
              : _CustomerBottomNav(context: context),
        );
      },
    );
  }
}

class _CustomerBottomNav extends StatelessWidget {
  const _CustomerBottomNav({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    var currentIndex = 0;
    if (location.startsWith(AppRoutes.feed)) {
      currentIndex = 1;
    } else if (location.startsWith(AppRoutes.orders)) {
      currentIndex = 2;
    } else if (location.startsWith(AppRoutes.profile)) {
      currentIndex = 3;
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go(AppRoutes.home);
            break;
          case 1:
            context.go(AppRoutes.feed);
            break;
          case 2:
            context.go(AppRoutes.orders);
            break;
          case 3:
            context.go(AppRoutes.profile);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_offer_outlined),
          selectedIcon: Icon(Icons.local_offer),
          label: 'Deals',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class _BusinessBottomNav extends StatelessWidget {
  const _BusinessBottomNav({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    // Business nav: My Deals | Add Deal | Orders | Analytics | Profile
    var currentIndex = 0;
    if (location.startsWith(AppRoutes.createDeal)) {
      currentIndex = 1;
    } else if (location.startsWith(AppRoutes.businessOrders)) {
      currentIndex = 2;
    } else if (location.startsWith(AppRoutes.analytics)) {
      currentIndex = 3;
    } else if (location.startsWith(AppRoutes.profile)) {
      currentIndex = 4;
    }
    // /home also maps to index 0 (My Deals) for business users on first load

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go(AppRoutes.businessDeals);
            break;
          case 1:
            context.go(AppRoutes.createDeal);
            break;
          case 2:
            context.go(AppRoutes.businessOrders);
            break;
          case 3:
            context.go(AppRoutes.analytics);
            break;
          case 4:
            context.go(AppRoutes.profile);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'My Deals',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: 'Add Deal',
        ),
        NavigationDestination(
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Analytics',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
