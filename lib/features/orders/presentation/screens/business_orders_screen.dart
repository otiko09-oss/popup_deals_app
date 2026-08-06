import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:popup_deals_app/features/orders/data/models/order_model.dart';
import '../providers/order_provider.dart';
import '../widgets/order_cards.dart';

/// Screen for businesses to manage incoming orders
class BusinessOrdersScreen extends ConsumerWidget {
  const BusinessOrdersScreen({
    required this.businessId,
    super.key,
  });
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersStream = ref.watch(businessOrdersStreamProvider(businessId));
    final updateState = ref.watch(orderStatusUpdateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Orders'),
        elevation: 0,
        centerTitle: false,
      ),
      body: ordersStream.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Orders will appear here',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          // Separate pending orders from completed
          final pendingOrders = orders
              .where((o) =>
                  o.status == OrderStatus.pending ||
                  o.status == OrderStatus.accepted ||
                  o.status == OrderStatus.ready)
              .toList();

          final completedOrders = orders
              .where((o) =>
                  o.status == OrderStatus.completed ||
                  o.status == OrderStatus.cancelled)
              .toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(
                      text: 'Active (${pendingOrders.length})',
                      icon: const Icon(Icons.schedule),
                    ),
                    Tab(
                      text: 'Completed (${completedOrders.length})',
                      icon: const Icon(Icons.done_all),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Active orders
                      RefreshIndicator(
                        onRefresh: () async {
                          final _ = ref.refresh(
                              businessOrdersStreamProvider(businessId));
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: pendingOrders.length,
                          itemBuilder: (context, index) {
                            final order = pendingOrders[index];
                            return _OrderCardWithActions(
                              order: order,
                              isLoading: updateState.isLoading,
                              onStatusUpdate: (newStatus) {
                                ref
                                    .read(orderStatusUpdateProvider.notifier)
                                    .updateOrderStatus(
                                      orderId: order.id,
                                      newStatus: newStatus,
                                    );
                              },
                            );
                          },
                        ),
                      ),

                      // Completed orders
                      RefreshIndicator(
                        onRefresh: () async {
                          final _ = ref.refresh(
                              businessOrdersStreamProvider(businessId));
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: completedOrders.length,
                          itemBuilder: (context, index) {
                            final order = completedOrders[index];
                            return _CompletedOrderCard(order: order);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                'Error loading orders',
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

/// Order card with action buttons
class _OrderCardWithActions extends ConsumerWidget {
  const _OrderCardWithActions({
    required this.order,
    required this.isLoading,
    required this.onStatusUpdate,
  });
  final OrderModel order;
  final bool isLoading;
  final Function(OrderStatus) onStatusUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) => BusinessOrderCard(
        order: order,
        isLoading: isLoading,
        onAccept: () {
          onStatusUpdate(OrderStatus.accepted);
        },
        onReady: () {
          onStatusUpdate(OrderStatus.ready);
        },
        onComplete: () {
          onStatusUpdate(OrderStatus.completed);
        },
        onCancel: () {
          _showCancelConfirmation(context, () {
            onStatusUpdate(OrderStatus.cancelled);
          });
        },
      );

  void _showCancelConfirmation(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text(
            'Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Cancel Order',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Display completed order (read-only)
class _CompletedOrderCard extends StatelessWidget {
  const _CompletedOrderCard({
    required this.order,
  });
  final OrderModel order;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.displayTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OrderStatusBadge(status: order.status, filled: true),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (order.dealImage.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order.dealImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.dealTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.userName} • \$${order.dealPrice.toStringAsFixed(2)}',
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
            ],
          ),
        ),
      );
}
