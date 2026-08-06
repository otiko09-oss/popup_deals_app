import 'package:equatable/equatable.dart';

enum RedemptionStatus { pending, redeemed, expired, cancelled }

class RedemptionModel extends Equatable {
  const RedemptionModel({
    required this.id,
    required this.orderId,
    required this.dealId,
    required this.userId,
    required this.businessId,
    required this.qrPayload,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.redeemedAt,
    this.dealTitle,
    this.businessName,
  });

  factory RedemptionModel.fromJson(Map<String, dynamic> json) =>
      RedemptionModel(
        id: json['id'] as String? ?? '',
        orderId: json['orderId'] as String? ?? '',
        dealId: json['dealId'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        businessId: json['businessId'] as String? ?? '',
        qrPayload: json['qrPayload'] as String? ?? '',
        status: RedemptionStatus.values.firstWhere(
          (s) => s.name == (json['status'] as String? ?? 'pending'),
          orElse: () => RedemptionStatus.pending,
        ),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : DateTime.now(),
        redeemedAt: json['redeemedAt'] != null
            ? DateTime.parse(json['redeemedAt'] as String)
            : null,
        dealTitle: json['dealTitle'] as String?,
        businessName: json['businessName'] as String?,
      );

  final String id;
  final String orderId;
  final String dealId;
  final String userId;
  final String businessId;
  final String qrPayload;
  final RedemptionStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? redeemedAt;
  final String? dealTitle;
  final String? businessName;

  bool get isValid =>
      status == RedemptionStatus.pending && DateTime.now().isBefore(expiresAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'dealId': dealId,
        'userId': userId,
        'businessId': businessId,
        'qrPayload': qrPayload,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'redeemedAt': redeemedAt?.toIso8601String(),
        'dealTitle': dealTitle,
        'businessName': businessName,
      };

  @override
  List<Object?> get props => [
        id,
        orderId,
        dealId,
        userId,
        businessId,
        qrPayload,
        status,
        createdAt,
        expiresAt,
        redeemedAt,
        dealTitle,
        businessName,
      ];
}
