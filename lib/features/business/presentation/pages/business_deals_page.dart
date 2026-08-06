import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:popup_deals_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:popup_deals_app/features/business/presentation/screens/business_deals_screen.dart';

class BusinessDealsPage extends ConsumerWidget {
  const BusinessDealsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

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
        return BusinessDealsScreen(businessId: firebaseUser.uid);
      },
    );
  }
}
