import 'package:flutter_test/flutter_test.dart';
import 'package:popup_deals_app/features/subscription/data/models/business_subscription.dart';

BusinessSubscription _trial({DateTime? expiresAt}) => BusinessSubscription(
      businessId: 'biz_1',
      planId: 'starter',
      status: 'trial',
      startedAt: DateTime.now(),
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 30)),
    );

void main() {
  group('BusinessSubscription trial', () {
    test('isTrialing is true for a fresh 30-day trial', () {
      final sub = _trial();
      expect(sub.isTrialing, isTrue);
      expect(sub.isActive, isTrue);
    });

    test('isTrialing is false once the trial has expired', () {
      final sub = _trial(
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(sub.isTrialing, isFalse);
      expect(sub.isActive, isFalse);
    });

    test('trialDaysRemaining is close to 30 right after starting', () {
      final sub = _trial();
      expect(sub.trialDaysRemaining, inInclusiveRange(29, 30));
    });

    test('trialDaysRemaining counts down correctly mid-trial', () {
      final sub =
          _trial(expiresAt: DateTime.now().add(const Duration(days: 5)));
      expect(sub.trialDaysRemaining, inInclusiveRange(4, 5));
    });

    test('trialDaysRemaining never goes negative after expiry', () {
      final sub = _trial(
        expiresAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(sub.trialDaysRemaining, 0);
    });

    test('a cancelled trial is not active even before its expiresAt', () {
      final sub = BusinessSubscription(
        businessId: 'biz_1',
        planId: 'starter',
        status: 'cancelled',
        startedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 10)),
      );
      expect(sub.isActive, isFalse);
      expect(sub.isTrialing, isFalse);
    });

    test('an active (paid) subscription is not reported as trialing', () {
      final sub = BusinessSubscription(
        businessId: 'biz_1',
        planId: 'growth',
        status: 'active',
        startedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(sub.isTrialing, isFalse);
      expect(sub.isActive, isTrue);
    });
  });
}
