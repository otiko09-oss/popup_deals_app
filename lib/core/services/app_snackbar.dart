import 'package:flutter/material.dart';
import 'haptic_service.dart';

enum SnackType { success, error, info, warning }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    SnackType type = SnackType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    switch (type) {
      case SnackType.success:
        HapticService.success();
        break;
      case SnackType.error:
        HapticService.error();
        break;
      default:
        HapticService.light();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_icon(type), color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _color(type),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      show(context,
          message: message,
          type: SnackType.success,
          actionLabel: actionLabel,
          onAction: onAction);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: SnackType.error);

  static void info(BuildContext context, String message) =>
      show(context, message: message);

  static Color _color(SnackType type) {
    switch (type) {
      case SnackType.success:
        return const Color(0xFF43A047);
      case SnackType.error:
        return const Color(0xFFE53935);
      case SnackType.warning:
        return const Color(0xFFFFA726);
      case SnackType.info:
        return const Color(0xFF1976D2);
    }
  }

  static IconData _icon(SnackType type) {
    switch (type) {
      case SnackType.success:
        return Icons.check_circle_outline;
      case SnackType.error:
        return Icons.error_outline;
      case SnackType.warning:
        return Icons.warning_amber_outlined;
      case SnackType.info:
        return Icons.info_outline;
    }
  }
}
