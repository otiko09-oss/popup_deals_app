import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/deals_provider.dart';
import '../providers/popup_deals_provider.dart';
import '../widgets/deal_card.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appUser = ref.watch(authProvider).asData?.value;
    final favoriteIds = appUser?.favorites ?? const <String>[];
    final locationAsync = ref.watch(userLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Deals'),
        centerTitle: false,
      ),
      body: favoriteIds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No saved deals yet',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any deal to save it here',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.feed),
                    icon: const Icon(Icons.local_offer_outlined),
                    label: const Text('Browse Deals'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteIds.length,
              itemBuilder: (context, index) => _FavoriteDealTile(
                dealId: favoriteIds[index],
                userLatitude: locationAsync.asData?.value?.latitude ?? 0,
                userLongitude: locationAsync.asData?.value?.longitude ?? 0,
              ),
            ),
    );
  }
}

class _FavoriteDealTile extends ConsumerWidget {
  const _FavoriteDealTile({
    required this.dealId,
    required this.userLatitude,
    required this.userLongitude,
  });
  final String dealId;
  final double userLatitude;
  final double userLongitude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealAsync = ref.watch(dealProvider(dealId));

    return dealAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => const SizedBox.shrink(),
      data: (deal) {
        if (deal == null) {
          // Deal no longer exists; nothing to show for this favorite.
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () {
              HapticService.light();
              context.push('${AppRoutes.dealDetail}/${deal.id}');
            },
            child: DealCard(
              deal: deal,
              userLatitude: userLatitude,
              userLongitude: userLongitude,
            ),
          ),
        );
      },
    );
  }
}
