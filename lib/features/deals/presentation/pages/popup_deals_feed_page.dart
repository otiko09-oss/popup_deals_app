import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:popup_deals_app/config/routes/app_routes.dart';
import 'package:popup_deals_app/core/services/haptic_service.dart';
import 'package:popup_deals_app/core/theme/app_theme.dart';
import 'package:popup_deals_app/core/widgets/skeleton_loader.dart';
import 'package:popup_deals_app/features/deals/presentation/providers/popup_deals_provider.dart';
import 'package:popup_deals_app/features/deals/presentation/widgets/deal_card.dart';

const _categories = [
  'All',
  'Pizza',
  'Burgers',
  'Sushi',
  'Salads',
  'Desserts',
  'Drinks',
  'Chicken',
  'Pasta',
];

class PopupDealsFeedPage extends ConsumerStatefulWidget {
  const PopupDealsFeedPage({super.key});

  @override
  ConsumerState<PopupDealsFeedPage> createState() => _PopupDealsFeedPageState();
}

class _PopupDealsFeedPageState extends ConsumerState<PopupDealsFeedPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _showBackToTop = false;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showBackToTop) {
        setState(() {
          _showBackToTop = show;
        });
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(userLocationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: locationAsync.when(
        loading: _buildLoadingScaffold,
        error: (_, __) => _buildLocationError(),
        data: (position) {
          if (position == null) return _buildLocationDenied();
          return _buildContent(position.latitude, position.longitude);
        },
      ),
      floatingActionButton: _showBackToTop
          ? FloatingActionButton.small(
              onPressed: () {
                HapticService.light();
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                );
              },
              tooltip: 'Back to top',
              child: const Icon(Icons.keyboard_arrow_up),
            ).animate().scale(duration: 200.ms)
          : null,
    );
  }

  Widget _buildContent(double lat, double lng) => NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Popup Deals'),
            actions: [
              IconButton(
                icon: const Icon(Icons.my_location_outlined),
                onPressed: () {
                  HapticService.light();
                  final _ = ref.refresh(userLocationProvider);
                },
                tooltip: 'Refresh location',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(116),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search deals, restaurants...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  HapticService.light();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  // Category chips
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      itemCount: _categories.length,
                      itemBuilder: (context, i) {
                        final cat = _categories[i];
                        final selected = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: selected,
                            onSelected: (_) {
                              HapticService.selection();
                              setState(() => _selectedCategory = cat);
                            },
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: _buildDealsList(lat, lng),
      );

  Widget _buildDealsList(double lat, double lng) {
    final dealsAsync = ref.watch(
      activeDealsNearbyStreamProvider((lat, lng)),
    );

    return dealsAsync.when(
      loading: () => const SingleChildScrollView(child: DealListSkeleton()),
      error: (error, _) =>
          _buildError(() => ref.invalidate(activeDealsNearbyStreamProvider)),
      data: (allDeals) {
        // Apply search + category filter
        final deals = allDeals.where((d) {
          final matchesSearch = _searchQuery.isEmpty ||
              d.title.toLowerCase().contains(_searchQuery) ||
              d.restaurant.toLowerCase().contains(_searchQuery) ||
              d.category.toLowerCase().contains(_searchQuery);
          final matchesCategory =
              _selectedCategory == 'All' || d.category == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        if (deals.isEmpty) {
          return _buildEmpty(
            icon: _searchQuery.isNotEmpty
                ? Icons.search_off_outlined
                : Icons.local_offer_outlined,
            title: _searchQuery.isNotEmpty
                ? 'No results for "$_searchQuery"'
                : 'No deals nearby',
            subtitle: _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Check back soon — new deals drop daily!',
            action: _searchQuery.isNotEmpty
                ? TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _selectedCategory = 'All');
                    },
                    child: const Text('Clear filters'),
                  )
                : null,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            HapticService.light();
            await ref
                .read(dealsRefreshProvider.notifier)
                .refreshDeals(latitude: lat, longitude: lng);
          },
          color: AppTheme.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: deals.length + (deals.isNotEmpty ? 1 : 0),
            itemBuilder: (context, i) {
              // Header count
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    '${deals.length} deal${deals.length == 1 ? '' : 's'} found',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              final deal = deals[i - 1];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: GestureDetector(
                  onTap: () {
                    HapticService.light();
                    context.push('${AppRoutes.dealDetail}/${deal.id}');
                  },
                  child: DealCard(
                    deal: deal,
                    userLatitude: lat,
                    userLongitude: lng,
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: (i - 1) * 40))
                  .fadeIn()
                  .slideY(begin: 0.08, end: 0);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingScaffold() => Scaffold(
        appBar: AppBar(title: const Text('Popup Deals')),
        body: const SingleChildScrollView(child: DealListSkeleton()),
      );

  Widget _buildLocationError() => Scaffold(
        appBar: AppBar(title: const Text('Popup Deals')),
        body: _buildEmpty(
          icon: Icons.location_off_outlined,
          title: 'Location unavailable',
          subtitle: 'Enable location to discover deals near you',
          action: FilledButton.icon(
            onPressed: () {
              final _ = ref.refresh(userLocationProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ),
      );

  Widget _buildLocationDenied() => Scaffold(
        appBar: AppBar(title: const Text('Popup Deals')),
        body: _buildEmpty(
          icon: Icons.location_disabled_outlined,
          title: 'Location access denied',
          subtitle: 'Grant location permission in settings to see nearby deals',
          action: FilledButton.icon(
            onPressed: () async {
              final svc = ref.read(locationServiceProvider);
              await svc.openAppSettings();
              final _ = ref.refresh(userLocationProvider);
            },
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Open Settings'),
          ),
        ),
      );

  Widget _buildError(VoidCallback onRetry) => _buildEmpty(
        icon: Icons.cloud_off_outlined,
        title: 'Failed to load deals',
        subtitle: 'Check your connection and try again',
        action: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 72, color: Colors.grey.shade300)
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text(title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 24), action],
            ],
          ),
        ),
      );
}
