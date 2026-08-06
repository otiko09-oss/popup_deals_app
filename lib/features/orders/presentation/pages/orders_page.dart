import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:popup_deals_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:popup_deals_app/features/orders/presentation/screens/business_orders_screen.dart';
import 'package:popup_deals_app/features/orders/presentation/screens/user_order_history_screen.dart';

/// Smart wrapper that shows either customer or business orders
/// based on the logged-in user type.
class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final appUser = ref.watch(authProvider).asData?.value;

    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (firebaseUser) {
        if (firebaseUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (appUser?.userType == 'restaurant') {
          return BusinessOrdersScreen(businessId: firebaseUser.uid);
        }

        return UserOrderHistoryScreen(userId: firebaseUser.uid);
      },
    );
  }
}
