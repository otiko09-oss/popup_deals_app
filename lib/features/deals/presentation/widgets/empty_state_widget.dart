import 'package:flutter/material.dart';
import 'package:popup_deals_app/core/theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.buttonText,
    this.onButtonPressed,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (buttonText != null && onButtonPressed != null) ...[
                  const SizedBox(height: AppTheme.spacingLg),
                  ElevatedButton(
                    onPressed: onButtonPressed,
                    child: Text(buttonText!),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
