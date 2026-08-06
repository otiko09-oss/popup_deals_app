import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:popup_deals_app/core/theme/app_theme.dart';
import 'package:popup_deals_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:popup_deals_app/features/deals/presentation/providers/deals_provider.dart';
import 'package:popup_deals_app/features/orders/presentation/widgets/reserve_button.dart';

class DealDetailPage extends ConsumerWidget {
  const DealDetailPage({
    required this.dealId,
    super.key,
  });
  final String dealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealAsync = ref.watch(dealProvider(dealId));

    return Scaffold(
      body: dealAsync.when(
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stackTrace) => Scaffold(
          body: Center(
            child: Text('Error loading deal: $error'),
          ),
        ),
        data: (deal) => deal == null
            ? Scaffold(
                body: Center(
                  child: Text(
                    'Deal not found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              )
            : CustomScrollView(
                slivers: [
                  // App Bar with image
                  SliverAppBar(
                    expandedHeight: 250,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        color: Colors.grey.shade300,
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                Icons.image,
                                size: 100,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            Positioned(
                              top: 50,
                              right: AppTheme.spacingMd,
                              child: _FavoriteButton(dealId: deal.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and discount
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  deal.title,
                                  style:
                                      Theme.of(context).textTheme.displaySmall,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingMd,
                                  vertical: AppTheme.spacingSm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                child: Text(
                                  '${deal.discountPercentage}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingMd),

                          // Restaurant info
                          GestureDetector(
                            onTap: () {
                              // Navigate to restaurant profile
                            },
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey.shade300,
                                    child: Icon(
                                      Icons.restaurant,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMd),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          deal.restaurant,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              size: 16,
                                              color: Colors.amber.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '4.5 (125 reviews)',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),

                          // Price section
                          Text(
                            'Price',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Row(
                            children: [
                              Text(
                                'Original: \$${deal.originalPrice.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                    ),
                              ),
                              const SizedBox(width: AppTheme.spacingLg),
                              Text(
                                'Now: \$${deal.discountedPrice.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: AppTheme.successColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingLg),

                          // Description
                          Text(
                            'About This Deal',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            deal.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppTheme.spacingLg),

                          // Details
                          Text(
                            'Details',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingMd),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: Column(
                              children: [
                                _DetailRow(
                                  label: 'Category',
                                  value: deal.category,
                                ),
                                const Divider(height: AppTheme.spacingLg),
                                _DetailRow(
                                  label: 'Expires',
                                  value: DateFormat('MMM dd, yyyy')
                                      .format(deal.expiresAt),
                                ),
                                const Divider(height: AppTheme.spacingLg),
                                _DetailRow(
                                  label: 'Redeemed',
                                  value: '${deal.redeemed} times',
                                ),
                                const Divider(height: AppTheme.spacingLg),
                                _DetailRow(
                                  label: 'Likes',
                                  value: '${deal.likes} people saved this',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXl),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: dealAsync.maybeWhen(
        data: (deal) {
          if (deal == null) {
            return null;
          }
          final appUser = ref.watch(authProvider).asData?.value;
          final firebaseUser = ref.watch(authStateProvider).asData?.value;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                children: [
                  Expanded(
                    child: _SaveButton(dealId: deal.id),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: appUser == null || firebaseUser == null
                        ? ElevatedButton(
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please sign in to reserve a deal'),
                              ),
                            ),
                            child: const Text('Reserve'),
                          )
                        : ReserveButton(
                            dealId: deal.id,
                            dealTitle: deal.title,
                            dealPrice: deal.discountedPrice,
                            businessId: deal.restaurantId,
                            businessName: deal.restaurant,
                            dealImage: deal.imageUrl,
                            businessLatitude: deal.latitude,
                            businessLongitude: deal.longitude,
                            userId: firebaseUser.uid,
                            userName: appUser.displayName?.isNotEmpty == true
                                ? appUser.displayName!
                                : appUser.email,
                            userPhone: firebaseUser.phoneNumber ?? '',
                          ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.dealId});
  final String dealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(authProvider).asData?.value;
    final isFavorite = appUser?.favorites.contains(dealId) ?? false;

    return CircleAvatar(
      backgroundColor: Colors.white,
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_outline,
          color: isFavorite ? Colors.red : null,
        ),
        onPressed: appUser == null
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please sign in to save deals'),
                  ),
                )
            : () => ref.read(authProvider.notifier).toggleFavorite(dealId),
      ),
    );
  }
}

class _SaveButton extends ConsumerWidget {
  const _SaveButton({required this.dealId});
  final String dealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(authProvider).asData?.value;
    final isFavorite = appUser?.favorites.contains(dealId) ?? false;

    return OutlinedButton.icon(
      onPressed: appUser == null
          ? () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please sign in to save deals'),
                ),
              )
          : () => ref.read(authProvider.notifier).toggleFavorite(dealId),
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_outline),
      label: Text(isFavorite ? 'Saved' : 'Save'),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      );
}
