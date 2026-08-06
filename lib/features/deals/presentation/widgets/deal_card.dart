import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:popup_deals_app/core/theme/app_theme.dart';
import 'package:popup_deals_app/features/deals/data/models/deal.dart';
import 'package:popup_deals_app/features/deals/presentation/providers/popup_deals_provider.dart';

class DealCard extends ConsumerWidget {
  const DealCard({
    required this.deal,
    required this.userLatitude,
    required this.userLongitude,
    super.key,
  });
  final Deal deal;
  final double userLatitude;
  final double userLongitude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distanceAsync = ref.watch(
      distanceToDealProvider(
          (userLatitude, userLongitude, deal.latitude, deal.longitude)),
    );
    final timeRemainingAsync =
        ref.watch(formattedTimeRemainingProvider(deal.endTime));

    return Container(
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
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              Stack(
                children: [
                  // Image
                  Container(
                    height: 220,
                    color: Colors.grey.shade300,
                    child: Image.network(
                      deal.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade300,
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade300,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Discount Badge (Top Right)
                  Positioned(
                    top: AppTheme.spacingMd,
                    right: AppTheme.spacingMd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentColor,
                            AppTheme.accentColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        '${deal.discountPercentage}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Timer Badge (Bottom Left)
                  Positioned(
                    bottom: AppTheme.spacingMd,
                    left: AppTheme.spacingMd,
                    child: timeRemainingAsync.when(
                      loading: () => const _TimerBadge(text: '...'),
                      error: (error, stackTrace) =>
                          const _TimerBadge(text: 'Soon'),
                      data: (timeText) => _TimerBadge(text: timeText),
                    ),
                  ),
                ],
              ),

              // Content Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      deal.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),

                    // Restaurant Name
                    Row(
                      children: [
                        const Icon(
                          Icons.restaurant,
                          size: 14,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            deal.restaurant,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // Price Section
                    Row(
                      children: [
                        // Original Price (Strikethrough)
                        Text(
                          '\$${deal.originalPrice.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey.shade500,
                                  ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        // New Price (Highlighted)
                        Text(
                          '\$${deal.discountedPrice.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // Distance Info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: distanceAsync.when(
                            loading: () => const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            error: (error, stackTrace) => Text(
                              'N/A km',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                            data: (distance) => Text(
                              '${distance.toStringAsFixed(1)} km',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.secondaryColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Text(
                            deal.category,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),

                    // Description (Optional)
                    if (deal.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                        child: Text(
                          deal.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Tags
                    if (deal.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                        child: Wrap(
                          spacing: AppTheme.spacingSm,
                          children: deal.tags
                              .take(3)
                              .map((tag) => Chip(
                                    label: Text(tag),
                                    backgroundColor: Colors.grey.shade200,
                                    labelStyle:
                                        Theme.of(context).textTheme.labelSmall,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingSm,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),

                    // Action Buttons
                    const SizedBox(height: AppTheme.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.favorite_border),
                            label: const Text('Save'),
                            onPressed: () {
                              // Add to favorites
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to favorites'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('View'),
                            onPressed: () {
                              // View deal details
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.schedule,
              size: 14,
              color: AppTheme.warningColor,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: AppTheme.warningColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}
