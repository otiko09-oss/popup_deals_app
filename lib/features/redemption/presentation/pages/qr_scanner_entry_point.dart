import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../business/presentation/pages/manage_staff_page.dart';
import 'qr_scanner_page.dart';

/// Resolves which business the signed-in user (owner or staff) is scanning
/// on behalf of, then shows the scanner. Staff members reach the same
/// scanner as owners — the only difference is where their businessId comes
/// from.
class QrScannerEntryPoint extends ConsumerWidget {
  const QrScannerEntryPoint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).asData?.value?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return FutureBuilder<String?>(
      future:
          ref.read(businessStaffServiceProvider).resolveActingBusinessId(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final businessId = snapshot.data;
        if (businessId == null) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "You're not linked to a business as an owner or staff "
                  'member, so there is nothing to scan for.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return QrScannerPage(businessId: businessId);
      },
    );
  }
}
