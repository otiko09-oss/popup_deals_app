import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../../../core/constants/subscription_plans.dart';
import '../models/business_subscription.dart';

/// Manages business subscriptions. Stripe checkout is wired via backend webhook.
class SubscriptionService {
  SubscriptionService({
    FirebaseFirestore? firestore,
    Logger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? Logger();

  final FirebaseFirestore _firestore;
  final Logger _logger;

  Future<BusinessSubscription?> getSubscription(String businessId) async {
    final doc =
        await _firestore.collection('subscriptions').doc(businessId).get();
    if (!doc.exists || doc.data() == null) return null;
    return BusinessSubscription.fromJson(doc.data()!);
  }

  Stream<BusinessSubscription?> subscriptionStream(String businessId) =>
      _firestore.collection('subscriptions').doc(businessId).snapshots().map(
            (doc) => doc.exists && doc.data() != null
                ? BusinessSubscription.fromJson(doc.data()!)
                : null,
          );

  /// MVP: activates plan locally. Replace with Stripe Checkout session in prod.
  Future<BusinessSubscription> activatePlan({
    required String businessId,
    required String planId,
  }) async {
    final plan = SubscriptionPlans.byId(planId);
    if (plan == null) {
      throw Exception('Invalid subscription plan');
    }

    final now = DateTime.now();
    final subscription = BusinessSubscription(
      businessId: businessId,
      planId: planId,
      status: 'active',
      startedAt: now,
      expiresAt: now.add(const Duration(days: 30)),
    );

    await _firestore
        .collection('subscriptions')
        .doc(businessId)
        .set(subscription.toJson());

    await _firestore.collection('businesses').doc(businessId).set({
      'subscriptionPlanId': planId,
      'subscriptionStatus': 'active',
      'maxActiveDeals': plan.maxActiveDeals,
      'updatedAt': now.toIso8601String(),
    }, SetOptions(merge: true));

    _logger.i('Subscription activated: $businessId -> $planId');
    return subscription;
  }

  Future<bool> canCreateDeal(String businessId) async {
    final subscription = await getSubscription(businessId);
    final planId = subscription?.planId ?? 'starter';
    final plan = SubscriptionPlans.byId(planId) ?? SubscriptionPlans.starter;

    if (subscription != null && !subscription.isActive) {
      return false;
    }

    final activeDeals = await _firestore
        .collection('deals')
        .where('restaurantId', isEqualTo: businessId)
        .where('isActive', isEqualTo: true)
        .count()
        .get();

    return (activeDeals.count ?? 0) < plan.maxActiveDeals;
  }

  Future<void> cancelSubscription(String businessId) async {
    await _firestore.collection('subscriptions').doc(businessId).update({
      'status': 'cancelled',
      'expiresAt': DateTime.now().toIso8601String(),
    });
  }
}
