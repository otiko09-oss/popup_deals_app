import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:popup_deals_app/features/orders/presentation/providers/order_provider.dart';
import 'package:popup_deals_app/features/redemption/presentation/pages/qr_redemption_page.dart';

/// ReserveButton widget for adding to DealCard
/// This button handles the reservation flow
class ReserveButton extends ConsumerStatefulWidget {
  const ReserveButton({
    required this.dealId,
    required this.dealTitle,
    required this.dealPrice,
    required this.businessId,
    required this.businessName,
    required this.dealImage,
    required this.businessLatitude,
    required this.businessLongitude,
    required this.userId,
    required this.userName,
    required this.userPhone,
    super.key,
  });
  final String dealId;
  final String dealTitle;
  final double dealPrice;
  final String businessId;
  final String businessName;
  final String dealImage;
  final double businessLatitude;
  final double businessLongitude;

  // User info - should be provided from auth state
  final String userId;
  final String userName;
  final String userPhone;

  @override
  ConsumerState<ReserveButton> createState() => _ReserveButtonState();
}

class _ReserveButtonState extends ConsumerState<ReserveButton> {
  @override
  Widget build(BuildContext context) {
    // Listen to order creation state for feedback
    ref.listen<OrderCreationState?>(
      orderCreationProvider,
      (previous, next) {
        if (next?.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next!.error!),
              backgroundColor: Colors.red,
            ),
          );
        } else if (next?.successMessage != null) {
          final redemption = next!.createdRedemption;
          if (redemption != null) {
            _showQrDialog(context, redemption);
          } else {
            _showSuccessDialog(context, next.createdOrderId ?? '');
          }
        }
      },
    );

    final creationState = ref.watch(orderCreationProvider);

    return ElevatedButton.icon(
      onPressed: creationState.isLoading ? null : _handleReserve,
      icon: creationState.isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.bookmark),
      label: Text(creationState.isLoading ? 'Claiming...' : 'Get QR Code'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _handleReserve() {
    // Import this in your file
    // import '../../../orders/presentation/widgets/reservation_dialogs.dart';

    showDialog(
      context: context,
      builder: (context) => _ReservationConfirmDialog(
        dealTitle: widget.dealTitle,
        dealPrice: widget.dealPrice,
        businessName: widget.businessName,
        onConfirm: () {
          Navigator.pop(context);
          _createOrder();
        },
      ),
    );
  }

  void _createOrder() {
    ref.read(orderCreationProvider.notifier).createOrder(
          userId: widget.userId,
          dealId: widget.dealId,
          businessId: widget.businessId,
          dealTitle: widget.dealTitle,
          dealPrice: widget.dealPrice,
          dealImage: widget.dealImage,
          userName: widget.userName,
          userPhone: widget.userPhone,
          businessName: widget.businessName,
          businessLatitude: widget.businessLatitude,
          businessLongitude: widget.businessLongitude,
        );
  }

  void _showQrDialog(BuildContext context, dynamic redemption) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deal Claimed!'),
        content: const Text(
          'Your QR code is ready. Show it at the business to redeem your deal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => QrRedemptionPage(redemption: redemption),
                ),
              );
            },
            child: const Text('View QR Code'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 48,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Reservation Confirmed!',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your reservation has been sent to ${widget.businessName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    orderId.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got It'),
            ),
          ),
        ],
      ),
    );
  }
}

// Confirmation dialog (inline to avoid circular imports)
class _ReservationConfirmDialog extends StatelessWidget {
  const _ReservationConfirmDialog({
    required this.dealTitle,
    required this.dealPrice,
    required this.businessName,
    required this.onConfirm,
  });
  final String dealTitle;
  final double dealPrice;
  final String businessName;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Reserve Deal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to reserve:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dealTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        businessName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '\$$dealPrice',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The restaurant will notify you when your order is ready for pickup.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
}

// Import this provider in your file
// import '../../orders/presentation/providers/order_provider.dart';
