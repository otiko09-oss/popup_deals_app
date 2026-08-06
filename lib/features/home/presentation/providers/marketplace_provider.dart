import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:popup_deals_app/core/services/location_service.dart';
import 'package:popup_deals_app/features/deals/data/models/deal.dart';
import 'package:popup_deals_app/features/deals/presentation/providers/deals_provider.dart';

final userLocationProvider = FutureProvider<(double, double)?>((ref) async {
  final locationService = LocationService();
  final position = await locationService.getCurrentLocation();
  if (position == null) return null;
  return (position.latitude, position.longitude);
});

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _toRad(double deg) => deg * math.pi / 180;

/// Recommended: highest discount among active deals.
final recommendedDealsProvider = Provider<List<Deal>>((ref) {
  final deals = ref.watch(dealsProvider).asData?.value ?? [];
  final sorted = [...deals]
    ..sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
  return sorted.take(10).toList();
});

/// Nearby: sorted by distance when location is available.
final nearbyDealsProvider = Provider<List<Deal>>((ref) {
  final deals = ref.watch(dealsProvider).asData?.value ?? [];
  final location = ref.watch(userLocationProvider).asData?.value;
  if (location == null) return deals.take(10).toList();

  final (userLat, userLon) = location;
  final withDistance = deals.map((deal) {
    final distance = _distanceKm(
      userLat,
      userLon,
      deal.latitude,
      deal.longitude,
    );
    return (deal, distance);
  }).toList()
    ..sort((a, b) => a.$2.compareTo(b.$2));

  return withDistance.take(10).map((e) => e.$1).toList();
});

/// Trending: most redeemed + likes.
final trendingDealsProvider = Provider<List<Deal>>((ref) {
  final deals = ref.watch(dealsProvider).asData?.value ?? [];
  final sorted = [...deals]
    ..sort((a, b) {
      final scoreA = a.redeemed * 2 + a.likes;
      final scoreB = b.redeemed * 2 + b.likes;
      return scoreB.compareTo(scoreA);
    });
  return sorted.take(10).toList();
});

/// New: most recently created.
final newDealsProvider = Provider<List<Deal>>((ref) {
  final deals = ref.watch(dealsProvider).asData?.value ?? [];
  final sorted = [...deals]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sorted.take(10).toList();
});

final dealsByMarketplaceCategoryProvider =
    Provider.family<List<Deal>, String>((ref, categoryId) {
  final deals = ref.watch(dealsProvider).asData?.value ?? [];
  return deals.where((d) => d.category == categoryId).take(10).toList();
});
