import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/subscription_plans.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/business_subscription.dart';
import '../../data/services/subscription_service.dart';

final subscriptionServiceProvider =
    Provider<SubscriptionService>((ref) => SubscriptionService());

final businessSubscriptionProvider =
    StreamProvider.family<BusinessSubscription?, String>((ref, businessId) {
  return ref.watch(subscriptionServiceProvider).subscriptionStream(businessId);
});

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({required this.businessId, super.key});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync =
        ref.watch(businessSubscriptionProvider(businessId));

    return Scaffold(
      appBar: AppBar(title: const Text('Business Subscription')),
      body: subscriptionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (current) => ListView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          children: [
            if (current != null && current.isActive)
              _CurrentPlanBanner(subscription: current),
            const SizedBox(height: 16),
            Text(
              'Choose a plan to publish deals and reach new customers.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            for (final plan in SubscriptionPlans.all)
              _PlanCard(
                plan: plan,
                isCurrent: current?.planId == plan.id && current!.isActive,
                onSelect: () async {
                  try {
                    await ref
                        .read(subscriptionServiceProvider)
                        .activatePlan(
                          businessId: businessId,
                          planId: plan.id,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${plan.name} plan activated!'),
                        ),
                      );
                    }
                  } on Object catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
              ),
            const SizedBox(height: 24),
            Text(
              'Payments via Stripe, Apple Pay, and Google Pay will be enabled '
              'when the backend checkout is connected.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPlanBanner extends StatelessWidget {
  const _CurrentPlanBanner({required this.subscription});
  final BusinessSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final plan =
        SubscriptionPlans.byId(subscription.planId) ?? SubscriptionPlans.starter;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryVariant],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Plan',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            plan.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subscription.expiresAt != null)
            Text(
              'Renews ${_formatDate(subscription.expiresAt!)}',
              style: const TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.onSelect,
  });

  final SubscriptionPlan plan;
  final bool isCurrent;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: plan.id == 'growth' ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: plan.id == 'growth'
              ? AppTheme.primaryColor
              : theme.colorScheme.outlineVariant,
          width: plan.id == 'growth' ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (plan.id == 'growth')
                  Chip(
                    label: const Text('Popular'),
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${plan.priceUsd.toStringAsFixed(0)}/month',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final feature in plan.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 18, color: AppTheme.successColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isCurrent ? null : onSelect,
                child: Text(isCurrent ? 'Current Plan' : 'Select ${plan.name}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
