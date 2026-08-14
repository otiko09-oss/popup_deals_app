import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/subscription_plans.dart';

/// Provides administrator-configured plans while keeping the app usable
/// before the optional `plans` collection has been seeded.
class PlansRepository {
  PlansRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<SubscriptionPlan>> activeStream() async* {
    try {
      await for (final snapshot in _firestore
          .collection('plans')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .snapshots()) {
        final plans = snapshot.docs
            .map((doc) => SubscriptionPlan.fromJson(doc.id, doc.data()))
            .toList();
        yield plans.isEmpty ? SubscriptionPlans.all : plans;
      }
    } on FirebaseException {
      // Plans are optional configuration; the built-in tiers remain a safe
      // fallback during first deployment or transient connection failures.
      yield SubscriptionPlans.all;
    }
  }
}
