import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/redemption_model.dart';
import '../../data/services/redemption_service.dart';

final redemptionServiceProvider =
    Provider<RedemptionService>((ref) => RedemptionService());

final userRedemptionsProvider =
    StreamProvider.family<List<RedemptionModel>, String>((ref, userId) {
  return ref.watch(redemptionServiceProvider).getUserRedemptionsStream(userId);
});

final redemptionProvider =
    FutureProvider.family<RedemptionModel?, String>((ref, redemptionId) {
  return ref.watch(redemptionServiceProvider).getRedemption(redemptionId);
});

class QrRedemptionPage extends ConsumerWidget {
  const QrRedemptionPage({
    required this.redemption,
    super.key,
  });

  final RedemptionModel redemption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your QR Code')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            Text(
              redemption.dealTitle ?? 'Deal',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              redemption.businessName ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            if (redemption.isValid)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: redemption.qrPayload,
                  size: 220,
                ),
              )
            else
              Icon(
                Icons.qr_code_2_outlined,
                size: 160,
                color: theme.colorScheme.outline,
              ),
            const SizedBox(height: 24),
            _StatusChip(redemption: redemption),
            const SizedBox(height: 16),
            Text(
              redemption.isValid
                  ? 'Show this QR code at ${redemption.businessName ?? 'the business'} '
                      'to redeem your deal.'
                  : 'This QR code can no longer be used.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            Text(
              'Expires: ${_formatDate(redemption.expiresAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.redemption});
  final RedemptionModel redemption;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (redemption.status) {
      RedemptionStatus.pending => ('Ready to use', Colors.green),
      RedemptionStatus.redeemed => ('Redeemed', Colors.blue),
      RedemptionStatus.expired => ('Expired', Colors.grey),
      RedemptionStatus.cancelled => ('Cancelled', Colors.red),
    };

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
