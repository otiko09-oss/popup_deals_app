import 'package:flutter_test/flutter_test.dart';
import 'package:popup_deals_app/core/constants/subscription_plans.dart';

void main() {
  group('SubscriptionPlans.byId', () {
    test('returns the matching plan for a known id', () {
      expect(SubscriptionPlans.byId('starter'), SubscriptionPlans.starter);
      expect(SubscriptionPlans.byId('growth'), SubscriptionPlans.growth);
      expect(SubscriptionPlans.byId('premium'), SubscriptionPlans.premium);
    });

    test('returns null for an unknown id', () {
      expect(SubscriptionPlans.byId('nonexistent'), isNull);
    });

    test('is case-sensitive (does not silently match a different case)', () {
      expect(SubscriptionPlans.byId('Starter'), isNull);
    });
  });

  group('SubscriptionPlans.all', () {
    test('contains exactly the three tiers in ascending price order', () {
      expect(SubscriptionPlans.all, [
        SubscriptionPlans.starter,
        SubscriptionPlans.growth,
        SubscriptionPlans.premium,
      ]);
      for (var i = 1; i < SubscriptionPlans.all.length; i++) {
        expect(
          SubscriptionPlans.all[i].priceUsd,
          greaterThan(SubscriptionPlans.all[i - 1].priceUsd),
        );
      }
    });

    test('each higher tier allows at least as many active deals', () {
      for (var i = 1; i < SubscriptionPlans.all.length; i++) {
        expect(
          SubscriptionPlans.all[i].maxActiveDeals,
          greaterThan(SubscriptionPlans.all[i - 1].maxActiveDeals),
        );
      }
    });
  });

  group('plan feature flags', () {
    test('starter has no premium features', () {
      expect(SubscriptionPlans.starter.hasAnalytics, isFalse);
      expect(SubscriptionPlans.starter.hasPriorityPlacement, isFalse);
      expect(SubscriptionPlans.starter.hasAdvertising, isFalse);
    });

    test('premium has every feature flag enabled', () {
      expect(SubscriptionPlans.premium.hasAnalytics, isTrue);
      expect(SubscriptionPlans.premium.hasPriorityPlacement, isTrue);
      expect(SubscriptionPlans.premium.hasAdvertising, isTrue);
    });
  });
}