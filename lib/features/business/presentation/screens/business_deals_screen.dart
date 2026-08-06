import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../config/routes/app_routes.dart';
import '../providers/business_provider.dart';

/// Screen showing all deals created by a business
class BusinessDealsScreen extends ConsumerWidget {
  const BusinessDealsScreen({
    required this.businessId,
    super.key,
  });
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsStream = ref.watch(businessDealsStreamProvider(businessId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Deals'),
        elevation: 0,
      ),
      body: dealsStream.when(
        data: (deals) {
          if (deals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No deals created yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first deal to get started',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Force refresh
              final _ = ref.refresh(businessDealsStreamProvider(businessId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deals.length,
              itemBuilder: (context, index) {
                final deal = deals[index];
                return _DealListTile(
                  deal: deal,
                  businessId: businessId,
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading deals',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual deal tile with actions
class _DealListTile extends ConsumerWidget {
  const _DealListTile({
    required this.deal,
    required this.businessId,
  });
  final Map<String, dynamic> deal;
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = deal['isActive'] as bool? ?? true;
    final toggleState = ref.watch(dealToggleProvider);

    final startTime = deal['startTime'] != null
        ? DateTime.parse(deal['startTime'] as String)
        : null;
    final endTime = deal['endTime'] != null
        ? DateTime.parse(deal['endTime'] as String)
        : null;

    final discountPercentage = deal['discountPercentage'] as num? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (deal['imageUrl'] != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.only(topLeft: Radius.circular(12)),
                  child: Image.network(
                    deal['imageUrl'] as String,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and discount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        deal['title'] as String? ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${discountPercentage.toStringAsFixed(0)}% OFF',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Prices
                Row(
                  children: [
                    Text(
                      '\$${deal['originalPrice']?.toString() ?? '0.00'}',
                      style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${deal['discountedPrice']?.toString() ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Time info
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        startTime != null && endTime != null
                            ? '${DateFormat('MMM dd, HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}'
                            : 'No time set',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatItem(
                      icon: Icons.favorite_outline,
                      label: 'Likes',
                      value: deal['likes']?.toString() ?? '0',
                    ),
                    _StatItem(
                      icon: Icons.check_circle_outline,
                      label: 'Redeemed',
                      value: deal['redeemed']?.toString() ?? '0',
                    ),
                    _StatItem(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: deal['category']?.toString() ?? 'N/A',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: toggleState.isLoading
                            ? null
                            : () {
                                ref
                                    .read(dealToggleProvider.notifier)
                                    .toggleDeal(
                                      deal['id'] as String,
                                      currentlyActive: isActive,
                                    );
                              },
                        icon: Icon(
                          isActive ? Icons.visibility_off : Icons.visibility,
                        ),
                        label: Text(isActive ? 'Deactivate' : 'Activate'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push(
                            '${AppRoutes.editDeal}/${deal['id']}',
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple stat display widget
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
}
