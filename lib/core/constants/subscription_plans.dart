/// Business subscription tiers for Popup Deals.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.priceUsd,
    required this.maxActiveDeals,
    required this.features,
    required this.hasAnalytics,
    required this.hasPriorityPlacement,
    required this.hasAdvertising,
  });

  final String id;
  final String name;
  final double priceUsd;
  final int maxActiveDeals;
  final List<String> features;
  final bool hasAnalytics;
  final bool hasPriorityPlacement;
  final bool hasAdvertising;
}

class SubscriptionPlans {
  static const starter = SubscriptionPlan(
    id: 'starter',
    name: 'Starter',
    priceUsd: 29,
    maxActiveDeals: 3,
    features: [
      'Up to 3 active deals',
      'Basic business profile',
      'QR redemption',
    ],
    hasAnalytics: false,
    hasPriorityPlacement: false,
    hasAdvertising: false,
  );

  static const growth = SubscriptionPlan(
    id: 'growth',
    name: 'Growth',
    priceUsd: 79,
    maxActiveDeals: 10,
    features: [
      'Up to 10 active deals',
      'Enhanced visibility',
      'Analytics dashboard',
      'QR redemption',
    ],
    hasAnalytics: true,
    hasPriorityPlacement: false,
    hasAdvertising: false,
  );

  static const premium = SubscriptionPlan(
    id: 'premium',
    name: 'Premium',
    priceUsd: 149,
    maxActiveDeals: 25,
    features: [
      'Up to 25 active deals',
      'Priority placement',
      'Featured advertising',
      'Advanced analytics',
      'QR redemption',
    ],
    hasAnalytics: true,
    hasPriorityPlacement: true,
    hasAdvertising: true,
  );

  static const List<SubscriptionPlan> all = [starter, growth, premium];

  static SubscriptionPlan? byId(String id) {
    for (final plan in all) {
      if (plan.id == id) return plan;
    }
    return null;
  }
}
