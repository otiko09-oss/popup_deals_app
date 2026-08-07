import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:logger/logger.dart';

import '../../../../core/constants/subscription_plans.dart';
import '../models/business_subscription.dart';

/// Manages business subscriptions.
///
/// Real payments go through Stripe Checkout: [startCheckout] calls the
/// `createCheckoutSession` Cloud Function (see /functions/index.js), which
/// returns a Stripe-hosted checkout URL. The subscription doc itself is
/// only ever written by that backend (webhook), never directly by the
/// client — see firestore.rules. [activatePlanForTesting] is kept only for
/// local development when Stripe isn't configured yet; it is intentionally
/// NOT wired to any UI button by default.
class SubscriptionService {
  SubscriptionService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    Logger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _logger = logger ?? Logger();

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final Logger _logger;

  /// Starts a real Stripe Checkout flow for [businessId] on [planId].
  /// Returns the Stripe-hosted checkout URL — open it with url_launcher
  /// (subscription_page.dart does this). The subscription becomes 'active'
  /// only after Stripe's webhook confirms payment — listen via
  /// [subscriptionStream] to reflect that in the UI.
  Future<String> startCheckout({
    required String businessId,
    required String planId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    final plan = SubscriptionPlans.byId(planId);
    if (plan == null) {
      throw Exception('Invalid subscription plan');
    }

    try {
      final callable = _functions.httpsCallable('createCheckoutSession');
      final result = await callable.call<Map<String, dynamic>>({
        'businessId': businessId,
        'planId': planId,
        if (successUrl != null) 'successUrl': successUrl,
        if (cancelUrl != null) 'cancelUrl': cancelUrl,
      });
      final url = result.data['url'] as String?;
      if (url == null) {
        throw Exception('Checkout session did not return a URL.');
      }
      _logger.i('Stripe checkout session created for $businessId -> $planId');
      return url;
    } on FirebaseFunctionsException catch (e) {
      _logger.e('createCheckoutSession failed: ${e.code} ${e.message}');
      rethrow;
    }
  }

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

  /// DEV/TEST ONLY — activates a plan locally without touching Stripe.
  /// Do not call this from production UI; real activation happens via the
  /// stripeWebhook Cloud Function after a successful Checkout session.
  /// Kept so you can exercise the app end-to-end before Stripe is configured.
  Future<BusinessSubscription> activatePlanForTesting({
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
