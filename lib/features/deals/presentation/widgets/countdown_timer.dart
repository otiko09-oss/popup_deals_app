import 'package:flutter/material.dart';
import 'package:popup_deals_app/core/theme/app_theme.dart';

class CountdownTimer extends StatelessWidget {
  const CountdownTimer({
    required this.endTime,
    super.key,
    this.style,
    this.showIcon = true,
  });
  final DateTime endTime;
  final TextStyle? style;
  final bool showIcon;

  String _getFormattedTime() {
    final remaining = endTime.difference(DateTime.now());

    if (remaining.isNegative) {
      return 'Expired';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m left';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s left';
    } else {
      return '${seconds}s left';
    }
  }

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            const Icon(
              Icons.schedule,
              size: 16,
              color: AppTheme.warningColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _getFormattedTime(),
            style: style ??
                const TextStyle(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
          ),
        ],
      );
}
