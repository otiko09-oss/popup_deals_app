import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:popup_deals_app/config/routes/app_routes.dart';
import 'package:popup_deals_app/core/theme/app_theme.dart';
import 'package:popup_deals_app/features/deals/presentation/providers/deals_provider.dart';

class DealsPage extends ConsumerStatefulWidget {
  const DealsPage({super.key});

  @override
  ConsumerState<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends ConsumerState<DealsPage> {
  late TextEditingController _searchController;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dealsAsync = _selectedCategory == 'All'
        ? ref.watch(dealsProvider)
        : ref.watch(dealsByCategoryProvider(_selectedCategory));

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Deals'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search deals...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Category Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              itemCount: 6,
              itemBuilder: (context, index) {
                final categories = [
                  'All',
                  'Burgers',
                  'Pizza',
                  'Sushi',
                  'Desserts',
                  'Drinks',
                ];
                final category = categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Deals List
          Expanded(
            child: dealsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Text('Error: $error'),
              ),
              data: (deals) => deals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            'No deals found',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          Text(
                            'Check back later for amazing offers',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd),
                      itemCount: deals.length,
                      itemBuilder: (context, index) {
                        final deal = deals[index];
                        return GestureDetector(
                          onTap: () {
                            context.push(
                              '${AppRoutes.dealDetail}/${deal.id}',
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.only(
                              bottom: AppTheme.spacingMd,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Image placeholder
                                Container(
                                  height: 200,
                                  color: Colors.grey.shade300,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Icon(
                                          Icons.image,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      // Discount badge
                                      Positioned(
                                        top: AppTheme.spacingMd,
                                        right: AppTheme.spacingMd,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppTheme.spacingMd,
                                            vertical: AppTheme.spacingSm,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentColor,
                                            borderRadius: BorderRadius.circular(
                                                AppTheme.radiusMd),
                                          ),
                                          child: Text(
                                            '${deal.discountPercentage}% OFF',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Deal info
                                Padding(
                                  padding:
                                      const EdgeInsets.all(AppTheme.spacingMd),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        deal.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(
                                          height: AppTheme.spacingSm),
                                      Text(
                                        deal.restaurant,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const SizedBox(
                                          height: AppTheme.spacingMd),
                                      Row(
                                        children: [
                                          Text(
                                            '\$${deal.originalPrice.toStringAsFixed(2)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  color: Colors.grey,
                                                ),
                                          ),
                                          const SizedBox(
                                              width: AppTheme.spacingMd),
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
                                      const SizedBox(
                                          height: AppTheme.spacingMd),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                // Add to favorites
                                              },
                                              child: const Text('♡ Save'),
                                            ),
                                          ),
                                          const SizedBox(
                                              width: AppTheme.spacingSm),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                // Redeem deal
                                              },
                                              child: const Text('Redeem'),
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
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
