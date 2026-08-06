import 'package:flutter/material.dart';
import 'package:popup_deals_app/features/orders/data/models/order_model.dart';

/// Widget displaying order status badge
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({
    required this.status,
    super.key,
    this.filled = false,
  });
  final OrderStatus status;
  final bool filled;

  Color get backgroundColor {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFFFA500).withValues(alpha: 0.2);
      case OrderStatus.accepted:
        return const Color(0xFF4169E1).withValues(alpha: 0.2);
      case OrderStatus.ready:
        return const Color(0xFF228B22).withValues(alpha: 0.2);
      case OrderStatus.completed:
        return const Color(0xFF00CED1).withValues(alpha: 0.2);
      case OrderStatus.cancelled:
        return const Color(0xFFDC143C).withValues(alpha: 0.2);
    }
  }

  Color get textColor {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFFFA500);
      case OrderStatus.accepted:
        return const Color(0xFF4169E1);
      case OrderStatus.ready:
        return const Color(0xFF228B22);
      case OrderStatus.completed:
        return const Color(0xFF00CED1);
      case OrderStatus.cancelled:
        return const Color(0xFFDC143C);
    }
  }

  IconData get icon {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.accepted:
        return Icons.check_circle;
      case OrderStatus.ready:
        return Icons.local_dining;
      case OrderStatus.completed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.close;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? textColor : backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: filled ? Colors.white : textColor,
            ),
            const SizedBox(width: 6),
            Text(
              status.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : textColor,
              ),
            ),
          ],
        ),
      );
}

/// Detailed order card for business dashboard
class BusinessOrderCard extends StatelessWidget {
  const BusinessOrderCard({
    required this.order,
    required this.onAccept,
    required this.onReady,
    required this.onComplete,
    required this.onCancel,
    super.key,
    this.isLoading = false,
  });
  final OrderModel order;
  final VoidCallback onAccept;
  final VoidCallback onReady;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final bool isLoading;

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
              // Header with status and time
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

              // Deal info
              Row(
                children: [
                  if (order.dealImage.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order.dealImage,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image),
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
                          'Qty: ${order.quantity} × \$${order.dealPrice.toStringAsFixed(2)}',
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
              const SizedBox(height: 12),

              // Customer info
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 18, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.userName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            order.userPhone,
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
              ),

              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 18, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.notes!,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  if (order.status == OrderStatus.pending)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  else if (order.status == OrderStatus.accepted)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onReady,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Mark Ready',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  else if (order.status == OrderStatus.ready)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Mark Completed',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  if (order.status != OrderStatus.completed &&
                      order.status != OrderStatus.cancelled)
                    const SizedBox(width: 8),
                  if (order.status != OrderStatus.completed &&
                      order.status != OrderStatus.cancelled)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}

/// Simple order card for user's order history
class UserOrderCard extends StatelessWidget {
  const UserOrderCard({
    required this.order,
    super.key,
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
                          order.dealTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.businessName,
                          style: TextStyle(
                            fontSize: 13,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        order.displayTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${order.dealPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
