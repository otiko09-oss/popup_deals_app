import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/services/app_snackbar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/redemption_service.dart';
import 'qr_redemption_page.dart';

class QrScannerPage extends ConsumerStatefulWidget {
  const QrScannerPage({required this.businessId, super.key});

  final String businessId;

  @override
  ConsumerState<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends ConsumerState<QrScannerPage> {
  bool _processing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;

    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    final redemptionId = parseRedemptionIdFromPayload(raw);
    if (redemptionId == null) return;

    setState(() => _processing = true);

    try {
      final redemption = await ref.read(redemptionServiceProvider).redeem(
            redemptionId: redemptionId,
            businessId: widget.businessId,
          );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Deal Redeemed!'),
          content: Text(
            '${redemption.dealTitle ?? 'Deal'} has been successfully redeemed.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on Object catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scan Customer QR')),
        body: Stack(
          children: [
            MobileScanner(onDetect: _onDetect),
            if (_processing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            Positioned(
              left: AppTheme.spacingLg,
              right: AppTheme.spacingLg,
              bottom: 32,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Point camera at customer QR code to validate and redeem the deal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
}
