import 'package:equatable/equatable.dart';

class BusinessSubscription extends Equatable {
  const BusinessSubscription({
    required this.businessId,
    required this.planId,
    required this.status,
    required this.startedAt,
    this.expiresAt,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
  });

  factory BusinessSubscription.fromJson(Map<String, dynamic> json) =>
      BusinessSubscription(
        businessId: json['businessId'] as String? ?? '',
        planId: json['planId'] as String? ?? 'starter',
        status: json['status'] as String? ?? 'inactive',
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : DateTime.now(),
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        stripeCustomerId: json['stripeCustomerId'] as String?,
        stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
      );

  final String businessId;
  final String planId;
  final String status; // active, inactive, cancelled, past_due
  final DateTime startedAt;
  final DateTime? expiresAt;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;

  bool get isActive =>
      status == 'active' &&
      (expiresAt == null || DateTime.now().isBefore(expiresAt!));

  Map<String, dynamic> toJson() => {
        'businessId': businessId,
        'planId': planId,
        'status': status,
        'startedAt': startedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'stripeCustomerId': stripeCustomerId,
        'stripeSubscriptionId': stripeSubscriptionId,
      };

  @override
  List<Object?> get props => [
        businessId,
        planId,
        status,
        startedAt,
        expiresAt,
        stripeCustomerId,
        stripeSubscriptionId,
      ];
}
