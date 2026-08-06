import 'package:flutter/material.dart';
import 'package:popup_deals_app/core/theme/app_theme.dart';

class LocationPermissionDialog extends StatelessWidget {
  const LocationPermissionDialog({
    required this.onAllowPressed,
    required this.onDenyPressed,
    super.key,
  });
  final VoidCallback onAllowPressed;
  final VoidCallback onDenyPressed;

  @override
  Widget build(BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('Location Permission'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We need your location to show deals nearby.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              'Your location will be used to:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            SizedBox(height: AppTheme.spacingSm),
            Padding(
              padding: EdgeInsets.only(left: AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Find deals within 10km'),
                  Text('• Show distance to restaurants'),
                  Text('• Personalize your feed'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: onDenyPressed,
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: onAllowPressed,
            child: const Text('Allow Location'),
          ),
        ],
      );
}
