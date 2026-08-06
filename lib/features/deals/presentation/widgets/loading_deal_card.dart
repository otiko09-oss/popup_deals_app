import 'package:flutter/material.dart';
import 'package:popup_deals_app/core/theme/app_theme.dart';

class LoadingDealCard extends StatelessWidget {
  const LoadingDealCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 220,
                color: Colors.grey.shade300,
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Container(
                      height: 12,
                      width: 200,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Container(
                      height: 12,
                      width: 100,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
