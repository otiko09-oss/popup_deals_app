import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:popup_deals_app/core/services/location_service.dart';
import 'package:popup_deals_app/features/deals/data/models/deal.dart';
import 'package:popup_deals_app/features/deals/data/services/deal_service.dart';

// Providers for services
final dealServiceProvider = Provider<DealService>((ref) => DealService());

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

// User location provider
final userLocationProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getCurrentLocation();
});

// Location stream provider
final userLocationStreamProvider = StreamProvider<Position?>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getLocationStream().handleError((error) => null);
});

// Check location service enabled
final isLocationServiceEnabledProvider = FutureProvider<bool>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.isLocationServiceEnabled();
});

// Active deals nearby provider (single fetch)
final activeDealsNearbyProvider =
    FutureProvider.family<List<Deal>, (double, double)>((ref, location) async {
  final dealService = ref.watch(dealServiceProvider);
  return dealService.getActiveDealsNearby(
    userLatitude: location.$1,
    userLongitude: location.$2,
  );
});

// Active deals nearby stream provider (real-time)
final activeDealsNearbyStreamProvider =
    StreamProvider.family<List<Deal>, (double, double)>((ref, location) {
  final dealService = ref.watch(dealServiceProvider);
  return dealService.getActiveDealsNearbyStream(
    userLatitude: location.$1,
    userLongitude: location.$2,
  );
});

// Deals by category provider
final dealsByCategoryNearbyProvider =
    FutureProvider.family<List<Deal>, (String, double, double)>(
  (ref, params) async {
    final dealService = ref.watch(dealServiceProvider);
    return dealService.getActiveDealsNearbyByCategory(
      userLatitude: params.$2,
      userLongitude: params.$3,
      category: params.$1,
    );
  },
);

// Search deals provider
final searchDealsProvider =
    FutureProvider.family<List<Deal>, (String, double, double)>(
  (ref, params) async {
    final dealService = ref.watch(dealServiceProvider);
    return dealService.searchDeals(
      query: params.$1,
      userLatitude: params.$2,
      userLongitude: params.$3,
    );
  },
);

// Single deal provider
final dealByIdProvider =
    FutureProvider.family<Deal?, String>((ref, dealId) async {
  final dealService = ref.watch(dealServiceProvider);
  return dealService.getDealById(dealId);
});

// Time remaining for deal (in seconds)
final timeRemainingProvider =
    StreamProvider.family<int, DateTime>((ref, endTime) async* {
  while (true) {
    final dealService = ref.watch(dealServiceProvider);
    final remaining = dealService.getTimeRemainingSeconds(endTime);

    yield remaining;

    if (remaining <= 0) {
      break;
    }

    // Update every second
    await Future.delayed(const Duration(seconds: 1));
  }
});

// Formatted time remaining for deal
final formattedTimeRemainingProvider =
    StreamProvider.family<String, DateTime>((ref, endTime) async* {
  while (true) {
    final dealService = ref.watch(dealServiceProvider);
    final formatted = dealService.getFormattedTimeRemaining(endTime);

    yield formatted;

    if (formatted == 'Expired') {
      break;
    }

    // Update every second
    await Future.delayed(const Duration(seconds: 1));
  }
});

// Distance to deal provider
final distanceToDealProvider =
    FutureProvider.family<double, (double, double, double, double)>(
  (ref, params) async {
    final dealService = ref.watch(dealServiceProvider);
    return dealService.getDistanceToDeal(
      userLatitude: params.$1,
      userLongitude: params.$2,
      dealLatitude: params.$3,
      dealLongitude: params.$4,
    );
  },
);

// Combined provider for PopUp deals feed with location
final popupDealsFeedProvider = StreamProvider<List<Deal>>((ref) async* {
  final locationService = ref.watch(locationServiceProvider);
  final dealService = ref.watch(dealServiceProvider);

  // Get initial location
  final position = await locationService.getCurrentLocation();
  if (position == null) {
    yield [];
    return;
  }

  // Start with initial data
  yield* dealService.getActiveDealsNearbyStream(
    userLatitude: position.latitude,
    userLongitude: position.longitude,
  );
});

// State notifier for managing deals feed state
class DealsRefreshNotifier extends StateNotifier<AsyncValue<List<Deal>>> {
  DealsRefreshNotifier(this.dealService, this.locationService)
      : super(const AsyncValue.loading());

  final DealService dealService;
  final LocationService locationService;

  Future<void> refreshDeals({
    required double latitude,
    required double longitude,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => dealService.getActiveDealsNearby(
          userLatitude: latitude,
          userLongitude: longitude,
        ));
  }

  Future<void> refreshDealsWithCurrentLocation() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final position = await locationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Could not get user location');
      }
      return dealService.getActiveDealsNearby(
        userLatitude: position.latitude,
        userLongitude: position.longitude,
      );
    });
  }
}

// Deals refresh provider
final dealsRefreshProvider =
    StateNotifierProvider<DealsRefreshNotifier, AsyncValue<List<Deal>>>((ref) {
  final dealService = ref.watch(dealServiceProvider);
  final locationService = ref.watch(locationServiceProvider);
  return DealsRefreshNotifier(dealService, locationService);
});
