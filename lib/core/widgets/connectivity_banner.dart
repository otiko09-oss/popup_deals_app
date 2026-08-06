import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream provider — emits true when online, false when offline
final connectivityProvider = StreamProvider<bool>((ref) => Connectivity()
    .onConnectivityChanged
    .map((result) => result != ConnectivityResult.none));

/// Banner shown at top when offline
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connAsync = ref.watch(connectivityProvider);

    final isOffline = connAsync.maybeWhen(
      data: (online) => !online,
      orElse: () => false,
    );

    return Column(
      children: [
        if (isOffline)
          Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              color: const Color(0xFFB71C1C),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'No internet connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .slideY(
                  begin: -1, end: 0, duration: 300.ms, curve: Curves.easeOut)
              .fadeIn(),
        Expanded(child: child),
      ],
    );
  }
}
