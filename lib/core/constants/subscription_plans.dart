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
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// Reads a plan document from the `plans` Firestore collection — see
  /// PlansRepository. [docId] is used as the plan id (the doc ID), so
  /// the 'id' field itself is optional in the stored data.
  factory SubscriptionPlan.fromJson(String docId, Map<String, dynamic> json) =>
      SubscriptionPlan(
        id: docId,
        name: json['name'] as String? ?? docId,
        priceUsd: (json['priceUsd'] as num?)?.toDouble() ?? 0,
        maxActiveDeals: json['maxActiveDeals'] as int? ?? 1,
        features: List<String>.from(json['features'] as List? ?? const []),
        hasAnalytics: json['hasAnalytics'] as bool? ?? false,
        hasPriorityPlacement: json['hasPriorityPlacement'] as bool? ?? false,
        hasAdvertising: json['hasAdvertising'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? true,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  final String id;
  final String name;
  final double priceUsd;
  final int maxActiveDeals;
  final List<String> features;
  final bool hasAnalytics;
  final bool hasPriorityPlacement;
  final bool hasAdvertising;
  final bool isActive;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'name': name,
        'priceUsd': priceUsd,
        'maxActiveDeals': maxActiveDeals,
        'features': features,
        'hasAnalytics': hasAnalytics,
        'hasPriorityPlacement': hasPriorityPlacement,
        'hasAdvertising': hasAdvertising,
        'isActive': isActive,
        'sortOrder': sortOrder,
      };
}

class SubscriptionPlans {
  static const starter = SubscriptionPlan(
    id: 'starter',
    name: 'Starter',
    priceUsd: 29,
    maxActiveDeals: 3,
    sortOrder: 0,
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
    sortOrder: 1,
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
    sortOrder: 2,
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