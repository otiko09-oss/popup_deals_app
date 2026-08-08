import 'package:flutter_test/flutter_test.dart';
import 'package:popup_deals_app/features/subscription/data/models/business_subscription.dart';

BusinessSubscription _sub({
  String status = 'active',
  DateTime? expiresAt,
}) =>
    BusinessSubscription(
      businessId: 'biz_1',
      planId: 'growth',
      status: status,
      startedAt: DateTime(2026, 1, 1),
      expiresAt: expiresAt,
    );

void main() {
  group('BusinessSubscription.isActive', () {
    test('is true when status is active and not expired', () {
      final sub = _sub(
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(days: 5)),
      );
      expect(sub.isActive, isTrue);
    });

    test('is true when status is active and there is no expiry set', () {
      final sub = _sub(status: 'active', expiresAt: null);
      expect(sub.isActive, isTrue);
    });

    test('is false once expiresAt is in the past, even if status says active',
        () {
      final sub = _sub(
        status: 'active',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(sub.isActive, isFalse);
    });

    test('is false for a cancelled subscription', () {
      final sub = _sub(status: 'cancelled');
      expect(sub.isActive, isFalse);
    });

    test('is false for a past_due subscription', () {
      final sub = _sub(status: 'past_due');
      expect(sub.isActive, isFalse);
    });
  });

  group('BusinessSubscription JSON round-trip', () {
    test('fromJson/toJson preserves all Stripe linkage fields', () {
      final original = BusinessSubscription(
        businessId: 'biz_1',
        planId: 'premium',
        status: 'active',
        startedAt: DateTime(2026, 3, 1),
        expiresAt: DateTime(2026, 4, 1),
        stripeCustomerId: 'cus_123',
        stripeSubscriptionId: 'sub_456',
      );

      final restored = BusinessSubscription.fromJson(original.toJson());

      expect(restored.stripeCustomerId, 'cus_123');
      expect(restored.stripeSubscriptionId, 'sub_456');
      expect(restored.planId, 'premium');
      expect(restored.isActive, original.isActive);
    });

    test('fromJson defaults missing planId to starter', () {
      final json = {
        'businessId': 'biz_1',
        'status': 'active',
        'startedAt': DateTime(2026, 1, 1).toIso8601String(),
      };
      final restored = BusinessSubscription.fromJson(json);
      expect(restored.planId, 'starter');
    });
  });
}