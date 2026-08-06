import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../providers/business_provider.dart';

/// Simple analytics dashboard for business users:
/// deal performance + order stats, all built from data that already
/// exists in Firestore (no extra backend work needed).
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'), elevation: 0),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (firebaseUser) {
          if (firebaseUser == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _AnalyticsBody(businessId: firebaseUser.uid);
        },
      ),
    );
  }
}

class _AnalyticsBody extends ConsumerWidget {
  const _AnalyticsBody({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(businessDealsStreamProvider(businessId));
    final pendingOrdersAsync = ref.watch(pendingOrderCountProvider(businessId));
    final todaysCompletedAsync =
        ref.watch(todaysCompletedOrderCountProvider(businessId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(businessDealsStreamProvider(businessId));
        ref.invalidate(pendingOrderCountProvider(businessId));
        ref.invalidate(todaysCompletedOrderCountProvider(businessId));
      },
      child: dealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading deals: $e')),
        data: (deals) {
          final activeDeals = deals.where((d) => d['isActive'] == true).length;
          final totalLikes = deals.fold<int>(
            0,
            (sum, d) => sum + ((d['likes'] as num?)?.toInt() ?? 0),
          );
          final totalRedeemed = deals.fold<int>(
            0,
            (sum, d) => sum + ((d['redeemed'] as num?)?.toInt() ?? 0),
          );

          final sortedByRedeemed = [...deals]..sort((a, b) =>
              ((b['redeemed'] as num?) ?? 0)
                  .compareTo((a['redeemed'] as num?) ?? 0));
          final topDeals = sortedByRedeemed.take(5).toList();

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      icon: Icons.local_offer,
                      label: 'Active Deals',
                      value: '$activeDeals',
                      color: Colors.green,
                    ),
                    _StatCard(
                      icon: Icons.storefront,
                      label: 'Total Deals',
                      value: '${deals.length}',
                      color: Colors.blue,
                    ),
                    _StatCard(
                      icon: Icons.favorite,
                      label: 'Total Saves',
                      value: '$totalLikes',
                      color: Colors.pink,
                    ),
                    _StatCard(
                      icon: Icons.check_circle,
                      label: 'Total Redeemed',
                      value: '$totalRedeemed',
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Orders',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.hourglass_top,
                        label: 'Pending Orders',
                        value: pendingOrdersAsync.when(
                          data: (v) => '$v',
                          loading: () => '…',
                          error: (_, __) => '-',
                        ),
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.today,
                        label: 'Completed Today',
                        value: todaysCompletedAsync.when(
                          data: (v) => '$v',
                          loading: () => '…',
                          error: (_, __) => '-',
                        ),
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Top Performing Deals',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (topDeals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No deals yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else
                  ...topDeals.map(
                    (deal) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        title: Text(
                          deal['title'] as String? ?? 'Untitled',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${deal['redeemed'] ?? 0} redeemed · '
                          '${deal['likes'] ?? 0} saves',
                        ),
                        trailing: Chip(
                          label: Text(
                            (deal['isActive'] == true) ? 'Active' : 'Inactive',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: (deal['isActive'] == true)
                              ? Colors.green
                              : Colors.grey,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      );
}
