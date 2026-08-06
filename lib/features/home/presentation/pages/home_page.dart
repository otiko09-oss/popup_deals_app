import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:popup_deals_app/config/routes/app_routes.dart';
import 'package:popup_deals_app/core/constants/marketplace_categories.dart';
import 'package:popup_deals_app/core/providers/locale_provider.dart';
import 'package:popup_deals_app/core/services/haptic_service.dart';
import 'package:popup_deals_app/core/theme/app_theme.dart';
import 'package:popup_deals_app/core/widgets/skeleton_loader.dart';
import 'package:popup_deals_app/features/deals/data/models/deal.dart';
import 'package:popup_deals_app/features/deals/presentation/providers/deals_provider.dart';
import 'package:popup_deals_app/features/home/presentation/providers/marketplace_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(dealsProvider);
    final locale = ref.watch(localeProvider).languageCode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticService.light();
          ref.invalidate(dealsProvider);
          ref.invalidate(userLocationProvider);
        },
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: Row(
                children: [
                  Icon(Icons.local_offer_rounded,
                      color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  const Text('Popup Deals',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    HapticService.light();
                    context.go(AppRoutes.feed);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_outline),
                  onPressed: () => context.push(AppRoutes.favorites),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: dealsAsync.when(
                loading: () => const DealListSkeleton(count: 3),
                error: (e, _) => _ErrorState(onRetry: () {
                  ref.invalidate(dealsProvider);
                }),
                data: (_) => _MarketplaceContent(locale: locale),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceContent extends ConsumerWidget {
  const _MarketplaceContent({required this.locale});
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommended = ref.watch(recommendedDealsProvider);
    final nearby = ref.watch(nearbyDealsProvider);
    final trending = ref.watch(trendingDealsProvider);
    final newest = ref.watch(newDealsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroBanner(onExplore: () => context.go(AppRoutes.feed))
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1),
        const SizedBox(height: 24),
        _SectionTitle(title: locale == 'ka' ? 'კატეგორიები' : 'Categories'),
        const SizedBox(height: 12),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final cat in MarketplaceCategories.all)
                _CategoryChip(
                  emoji: cat.emoji,
                  label: cat.label(locale),
                  onTap: () => context.go(AppRoutes.feed),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _DealSection(
          title: locale == 'ka' ? 'რეკომენდებული' : 'Recommended Deals',
          deals: recommended,
        ),
        _DealSection(
          title: locale == 'ka' ? 'ახლოს' : 'Nearby Deals',
          deals: nearby,
        ),
        _DealSection(
          title: locale == 'ka' ? 'ტრენდული' : 'Trending Deals',
          deals: trending,
        ),
        _DealSection(
          title: locale == 'ka' ? 'ახალი' : 'New Deals',
          deals: newest,
        ),
        if (recommended.isEmpty &&
            nearby.isEmpty &&
            trending.isEmpty &&
            newest.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.storefront_outlined,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No deals yet — check back soon!',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, AppTheme.primaryVariant],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Global Deals Marketplace',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Food · Hotels · Beauty · Fitness · More',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onExplore,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Explore Deals'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.go(AppRoutes.feed),
              child: const Text('See All →'),
            ),
          ],
        ),
      );
}

class _DealSection extends StatelessWidget {
  const _DealSection({required this.title, required this.deals});
  final String title;
  final List<Deal> deals;

  @override
  Widget build(BuildContext context) {
    if (deals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: deals.length > 8 ? 8 : deals.length,
            itemBuilder: (context, i) => _HorizontalDealCard(deal: deals[i]),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _HorizontalDealCard extends StatelessWidget {
  const _HorizontalDealCard({required this.deal});
  final Deal deal;

  @override
  Widget build(BuildContext context) {
    final category = MarketplaceCategories.byId(deal.category);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        context.push('${AppRoutes.dealDetail}/${deal.id}');
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: deal.imageUrl,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${deal.discountPercentage}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category != null
                        ? '${category.emoji} ${category.labelEn}'
                        : deal.restaurant,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.cloud_off_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Failed to load deals'),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
