import 'package:flutter_test/flutter_test.dart';
import 'package:popup_deals_app/features/orders/data/models/order_model.dart';

void main() {
  group('OrderStatus.fromString', () {
    test('maps every known status string to its enum value', () {
      expect(OrderStatus.fromString('pending'), OrderStatus.pending);
      expect(OrderStatus.fromString('accepted'), OrderStatus.accepted);
      expect(OrderStatus.fromString('ready'), OrderStatus.ready);
      expect(OrderStatus.fromString('completed'), OrderStatus.completed);
      expect(OrderStatus.fromString('cancelled'), OrderStatus.cancelled);
    });

    test('falls back to pending for an unrecognized string instead of throwing', () {
      expect(OrderStatus.fromString('some_typo'), OrderStatus.pending);
      expect(OrderStatus.fromString(''), OrderStatus.pending);
    });

    test('is case-sensitive — a wrong-case value falls back to pending', () {
      expect(OrderStatus.fromString('Pending'), OrderStatus.pending);
    });

    test('round-trips through .name for every enum value', () {
      for (final status in OrderStatus.values) {
        expect(OrderStatus.fromString(status.name), status);
      }
    });
  });

  group('OrderStatus.displayName', () {
    test('has a non-empty, human-readable label for every value', () {
      for (final status in OrderStatus.values) {
        expect(status.displayName, isNotEmpty);
        expect(status.displayName, isNot(equals(status.name)));
      }
    });
  });

  group('OrderStatus.displayColor', () {
    test('is a valid 6-digit hex color for every value', () {
      final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
      for (final status in OrderStatus.values) {
        expect(hexPattern.hasMatch(status.displayColor), isTrue,
            reason: '${status.name} has an invalid color: ${status.displayColor}');
      }
    });

    test('every status has a distinct color', () {
      final colors = OrderStatus.values.map((s) => s.displayColor).toSet();
      expect(colors.length, OrderStatus.values.length);
    });
  });

  group('OrderModel JSON round-trip', () {
    OrderModel baseOrder({String status = 'pending'}) => OrderModel.fromJson({
          'id': 'order_1',
          'userId': 'user_1',
          'dealId': 'deal_1',
          'businessId': 'biz_1',
          'status': status,
          'createdAt': DateTime(2026, 1, 1).toIso8601String(),
          'dealTitle': '2-for-1 Pizza',
          'dealPrice': 12.5,
          'dealImage': 'https://example.com/pizza.jpg',
          'userName': 'Ana',
          'userPhone': '+995500000000',
          'businessName': 'Pizza Place',
          'businessLatitude': 41.7,
          'businessLongitude': 44.8,
        });

    test('missing optional timestamps become null, not a parse error', () {
      final order = baseOrder();
      expect(order.updatedAt, isNull);
      expect(order.acceptedAt, isNull);
      expect(order.readyAt, isNull);
      expect(order.completedAt, isNull);
    });

    test('missing quantity defaults to 1', () {
      final order = baseOrder();
      expect(order.quantity, 1);
    });

    test('status string maps correctly through the full model', () {
      expect(baseOrder(status: 'ready').status, OrderStatus.ready);
    });

    test('toJson/fromJson preserves status as its string name', () {
      final order = baseOrder(status: 'accepted');
      final json = order.toJson();
      expect(json['status'], 'accepted');
    });
  });
}