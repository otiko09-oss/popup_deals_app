import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:popup_deals_app/features/orders/data/models/order_model.dart';
import 'package:popup_deals_app/features/redemption/presentation/pages/qr_redemption_page.dart';
import 'package:popup_deals_app/features/reviews/presentation/providers/review_provider.dart';
import 'package:popup_deals_app/features/reviews/presentation/widgets/review_form_dialog.dart';
import '../providers/order_provider.dart';
import '../widgets/order_cards.dart';

/// Screen showing user's order history
class UserOrderHistoryScreen extends ConsumerWidget {
  const UserOrderHistoryScreen({
    required this.userId,
    super.key,
  });
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersStream = ref.watch(userOrdersStreamProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        elevation: 0,
      ),
      body: ordersStream.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reservations yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reserve deals to see them here',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to deals feed
                      // Navigator.pushNamed(context, '/popup-deals');
                    },
                    child: const Text('Browse Deals'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final _ = ref.refresh(userOrdersStreamProvider(userId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return GestureDetector(
                  onTap: () {
                    _showOrderDetails(context, order);
                  },
                  child: UserOrderCard(order: order),
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
                'Error loading reservations',
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

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _OrderDetailsSheet(order: order),
    );
  }
}

/// Bottom sheet showing order details
class _OrderDetailsSheet extends ConsumerWidget {
  const _OrderDetailsSheet({
    required this.order,
  });
  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final redemptionAsync = order.redemptionId?.isNotEmpty == true
        ? ref.watch(redemptionProvider(order.redemptionId!))
        : null;

    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                OrderStatusBadge(status: order.status, filled: true),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Deal info
            Text(
              'Deal',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.dealTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        '\$${order.dealPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        '${order.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Restaurant info
            Text(
              'Restaurant',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.businessName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        order.userPhone,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Timeline
            Text(
              'Timeline',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            _TimelineItem(
              icon: Icons.schedule,
              title: 'Ordered',
              time: order.createdAt,
            ),
            if (order.acceptedAt != null)
              _TimelineItem(
                icon: Icons.check_circle,
                title: 'Accepted',
                time: order.acceptedAt!,
              ),
            if (order.readyAt != null)
              _TimelineItem(
                icon: Icons.local_dining,
                title: 'Ready',
                time: order.readyAt!,
              ),
            if (order.completedAt != null)
              _TimelineItem(
                icon: Icons.done_all,
                title: 'Completed',
                time: order.completedAt!,
              ),

            if (redemptionAsync != null) ...[
              const SizedBox(height: 8),
              redemptionAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => const Text(
                  'Could not load this reservation QR code.',
                  textAlign: TextAlign.center,
                ),
                data: (redemption) => redemption == null
                    ? const SizedBox.shrink()
                    : SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.qr_code_2_outlined),
                          label: Text(
                            redemption.isValid
                                ? 'Show QR Code'
                                : 'View QR Status',
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  QrRedemptionPage(redemption: redemption),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
            if (order.status == OrderStatus.completed) ...[
              const SizedBox(height: 8),
              ref.watch(reviewForOrderProvider(order.id)).when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (_, __) => const Text(
                      'Could not load your review status.',
                      textAlign: TextAlign.center,
                    ),
                    data: (review) => SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(
                          review == null
                              ? Icons.star_outline
                              : Icons.edit_outlined,
                        ),
                        label: Text(
                          review == null ? 'Rate this deal' : 'Edit your review',
                        ),
                        onPressed: () async {
                          final saved = await showDialog<bool>(
                            context: context,
                            builder: (_) => ReviewFormDialog(orderId: order.id),
                          );
                          if (saved == true) {
                            ref.invalidate(reviewForOrderProvider(order.id));
                          }
                        },
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      );
  }
}

/// Timeline item widget
class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.time,
  });
  final IconData icon;
  final String title;
  final DateTime time;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.green.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    time.toString().split('.')[0],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
