import 'package:flutter_test/flutter_test.dart';
import 'package:popup_deals_app/features/deals/data/models/deal.dart';

Map<String, dynamic> _baseJson({
  Object? originalPrice = 20,
  Object? discountedPrice = 12.5,
  Object? latitude = 41,
  Object? longitude = 44,
}) =>
    {
      'id': 'deal_1',
      'title': '2-for-1 Pizza',
      'description': 'Buy one pizza, get one free.',
      'imageUrl': 'https://example.com/pizza.jpg',
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discountPercentage': 38,
      'category': 'Food',
      'restaurant': 'Pizza Place',
      'restaurantId': 'biz_1',
      'startTime': DateTime(2026, 1, 1, 10).toIso8601String(),
      'endTime': DateTime(2026, 1, 1, 22).toIso8601String(),
      'expiresAt': DateTime(2026, 1, 2).toIso8601String(),
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      'isActive': true,
      'likes': 4,
      'redeemed': 1,
      'tags': ['pizza', 'buy-one-get-one'],
      'latitude': latitude,
      'longitude': longitude,
    };

void main() {
  group('Deal.fromJson numeric parsing', () {
    test('accepts integer price values from Firestore, not just doubles', () {
      final deal =
          Deal.fromJson(_baseJson(originalPrice: 20, discountedPrice: 12));
      expect(deal.originalPrice, 20.0);
      expect(deal.discountedPrice, 12.0);
      expect(deal.originalPrice, isA<double>());
    });

    test('accepts integer latitude/longitude values', () {
      final deal = Deal.fromJson(_baseJson(latitude: 41, longitude: 44));
      expect(deal.latitude, 41.0);
      expect(deal.longitude, 44.0);
    });
  });

  group('Deal JSON round-trip', () {
    test('toJson/fromJson preserves every field exactly', () {
      final original = Deal.fromJson(_baseJson());
      final restored = Deal.fromJson(original.toJson());

      expect(restored, original);
    });

    test('preserves optional restaurant contact fields when present', () {
      final json = _baseJson()
        ..['restaurantPhoneNumber'] = '+995500000000'
        ..['restaurantAddress'] = '12 Rustaveli Ave';
      final deal = Deal.fromJson(json);

      expect(deal.restaurantPhoneNumber, '+995500000000');
      expect(deal.restaurantAddress, '12 Rustaveli Ave');
    });

    test('leaves optional restaurant contact fields null when absent', () {
      final deal = Deal.fromJson(_baseJson());
      expect(deal.restaurantPhoneNumber, isNull);
      expect(deal.restaurantAddress, isNull);
    });

    test('preserves the tags list contents and order', () {
      final deal = Deal.fromJson(_baseJson());
      expect(deal.tags, ['pizza', 'buy-one-get-one']);
    });
  });
}
