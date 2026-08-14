import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/subscription_plans.dart';
import '../services/plans_repository.dart';

final plansRepositoryProvider =
    Provider<PlansRepository>((ref) => PlansRepository());

/// Admin-configurable subscription plans, live from Firestore. Falls back
/// to the hardcoded [SubscriptionPlans.all] tiers automatically (inside
/// the repository) whenever the `plans` collection hasn't been seeded yet.
final activePlansProvider = StreamProvider<List<SubscriptionPlan>>((ref) {
  return ref.watch(plansRepositoryProvider).activeStream();
});
