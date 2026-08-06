import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/deal.dart';

class DealService {
  DealService({FirebaseFirestore? firestore, Logger? logger})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? Logger();
  final FirebaseFirestore _firestore;
  final Logger _logger;

  static const String dealsCollection = 'deals';
  static const double radiusInKm = 10;

  /// Haversine formula — uses dart:math (accurate & fast)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // π / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742.0 * math.asin(math.sqrt(a));
  }

  bool _isDealTimeActive(DateTime startTime, DateTime endTime) {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  Future<List<Deal>> getActiveDealsNearby({
    required double userLatitude,
    required double userLongitude,
    double radiusKm = radiusInKm,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(dealsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final deals = <Deal>[];

      for (final doc in snapshot.docs) {
        try {
          final deal = Deal.fromJson({'id': doc.id, ...doc.data()});
          if (!_isDealTimeActive(deal.startTime, deal.endTime)) {
            continue;
          }

          final dist = _calculateDistance(
            userLatitude,
            userLongitude,
            deal.latitude,
            deal.longitude,
          );
          if (dist <= radiusKm) {
            deals.add(deal);
          }
        } catch (e) {
          _logger.w('Skipping deal ${doc.id}: $e');
        }
      }

      deals.sort((a, b) => _calculateDistance(
              userLatitude, userLongitude, a.latitude, a.longitude)
          .compareTo(_calculateDistance(
              userLatitude, userLongitude, b.latitude, b.longitude)));

      _logger.i('Found ${deals.length} nearby deals');
      return deals;
    } catch (e) {
      _logger.e('Error fetching nearby deals: $e');
      rethrow;
    }
  }

  Stream<List<Deal>> getActiveDealsNearbyStream({
    required double userLatitude,
    required double userLongitude,
    double radiusKm = radiusInKm,
  }) =>
      _firestore
          .collection(dealsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final deals = <Deal>[];
        for (final doc in snapshot.docs) {
          try {
            final deal = Deal.fromJson({'id': doc.id, ...doc.data()});
            if (!_isDealTimeActive(deal.startTime, deal.endTime)) continue;
            final dist = _calculateDistance(
                userLatitude, userLongitude, deal.latitude, deal.longitude);
            if (dist <= radiusKm) deals.add(deal);
          } catch (e) {
            _logger.w('Skipping deal: $e');
          }
        }
        deals.sort((a, b) => _calculateDistance(
                userLatitude, userLongitude, a.latitude, a.longitude)
            .compareTo(_calculateDistance(
                userLatitude, userLongitude, b.latitude, b.longitude)));
        return deals;
      });

  Future<List<Deal>> getActiveDealsNearbyByCategory({
    required double userLatitude,
    required double userLongitude,
    required String category,
    double radiusKm = radiusInKm,
  }) async {
    final snapshot = await _firestore
        .collection(dealsCollection)
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('discountPercentage', descending: true)
        .get();

    final deals = <Deal>[];
    for (final doc in snapshot.docs) {
      try {
        final deal = Deal.fromJson({'id': doc.id, ...doc.data()});
        if (!_isDealTimeActive(deal.startTime, deal.endTime)) continue;
        final dist = _calculateDistance(
            userLatitude, userLongitude, deal.latitude, deal.longitude);
        if (dist <= radiusKm) deals.add(deal);
      } catch (e) {
        _logger.w('Skipping deal: $e');
      }
    }
    return deals;
  }

  Future<Deal?> getDealById(String dealId) async {
    final doc = await _firestore.collection(dealsCollection).doc(dealId).get();
    if (!doc.exists) {
      return null;
    }
    return Deal.fromJson({'id': doc.id, ...doc.data()!});
  }

  Future<List<Deal>> searchDeals({
    required String query,
    required double userLatitude,
    required double userLongitude,
    double radiusKm = radiusInKm,
  }) async {
    final snapshot = await _firestore
        .collection(dealsCollection)
        .where('isActive', isEqualTo: true)
        .get();

    final deals = <Deal>[];
    final lq = query.toLowerCase();

    for (final doc in snapshot.docs) {
      try {
        final deal = Deal.fromJson({'id': doc.id, ...doc.data()});
        if (!_isDealTimeActive(deal.startTime, deal.endTime)) continue;
        if (!deal.title.toLowerCase().contains(lq) &&
            !deal.description.toLowerCase().contains(lq)) {
          continue;
        }
        final dist = _calculateDistance(
            userLatitude, userLongitude, deal.latitude, deal.longitude);
        if (dist <= radiusKm) deals.add(deal);
      } catch (e) {
        _logger.w('Skipping deal: $e');
      }
    }
    return deals;
  }

  int getTimeRemainingSeconds(DateTime endTime) {
    final remaining = endTime.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  double getDistanceToDeal({
    required double userLatitude,
    required double userLongitude,
    required double dealLatitude,
    required double dealLongitude,
  }) =>
      _calculateDistance(
        userLatitude,
        userLongitude,
        dealLatitude,
        dealLongitude,
      );

  String getFormattedTimeRemaining(DateTime endTime) {
    final remaining = endTime.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'Expired';
    }
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    if (m > 0) {
      return '${m}m ${s}s';
    }
    return '${s}s';
  }
}
