import 'package:equatable/equatable.dart';

/// Order status enumeration
enum OrderStatus {
  pending,
  accepted,
  ready,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get displayColor {
    switch (this) {
      case OrderStatus.pending:
        return '#FFA500'; // Orange
      case OrderStatus.accepted:
        return '#4169E1'; // Royal Blue
      case OrderStatus.ready:
        return '#228B22'; // Forest Green
      case OrderStatus.completed:
        return '#00CED1'; // Dark Turquoise
      case OrderStatus.cancelled:
        return '#DC143C'; // Crimson
    }
  }

  static OrderStatus fromString(String status) => OrderStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => OrderStatus.pending,
      );
}

/// OrderModel represents a deal reservation/order
class OrderModel extends Equatable {
  const OrderModel({
    required this.id,
    required this.userId,
    required this.dealId,
    required this.businessId,
    required this.status,
    required this.createdAt,
    required this.dealTitle,
    required this.dealPrice,
    required this.dealImage,
    required this.userName,
    required this.userPhone,
    required this.businessName,
    required this.businessLatitude,
    required this.businessLongitude,
    this.updatedAt,
    this.acceptedAt,
    this.readyAt,
    this.completedAt,
    this.notes,
    this.quantity = 1,
  });

  /// Create OrderModel from Firestore JSON
  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        dealId: json['dealId'] as String? ?? '',
        businessId: json['businessId'] as String? ?? '',
        status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        acceptedAt: json['acceptedAt'] != null
            ? DateTime.parse(json['acceptedAt'] as String)
            : null,
        readyAt: json['readyAt'] != null
            ? DateTime.parse(json['readyAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        dealTitle: json['dealTitle'] as String? ?? '',
        dealPrice: (json['dealPrice'] as num?)?.toDouble() ?? 0.0,
        dealImage: json['dealImage'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        userPhone: json['userPhone'] as String? ?? '',
        businessName: json['businessName'] as String? ?? '',
        businessLatitude: (json['businessLatitude'] as num?)?.toDouble() ?? 0.0,
        businessLongitude:
            (json['businessLongitude'] as num?)?.toDouble() ?? 0.0,
        notes: json['notes'] as String?,
        quantity: json['quantity'] as int? ?? 1,
      );
  final String id;
  final String userId;
  final String dealId;
  final String businessId;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? completedAt;

  // Deal details snapshot at order time
  final String dealTitle;
  final double dealPrice;
  final String dealImage;

  // User info
  final String userName;
  final String userPhone;

  // Business info
  final String businessName;
  final double businessLatitude;
  final double businessLongitude;

  // Notes
  final String? notes;
  final int quantity;

  /// Convert OrderModel to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'dealId': dealId,
        'businessId': businessId,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'readyAt': readyAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'dealTitle': dealTitle,
        'dealPrice': dealPrice,
        'dealImage': dealImage,
        'userName': userName,
        'userPhone': userPhone,
        'businessName': businessName,
        'businessLatitude': businessLatitude,
        'businessLongitude': businessLongitude,
        'notes': notes,
        'quantity': quantity,
      };

  /// Create a copy with updated fields
  OrderModel copyWith({
    String? id,
    String? userId,
    String? dealId,
    String? businessId,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? readyAt,
    DateTime? completedAt,
    String? dealTitle,
    double? dealPrice,
    String? dealImage,
    String? userName,
    String? userPhone,
    String? businessName,
    double? businessLatitude,
    double? businessLongitude,
    String? notes,
    int? quantity,
  }) =>
      OrderModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        dealId: dealId ?? this.dealId,
        businessId: businessId ?? this.businessId,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        readyAt: readyAt ?? this.readyAt,
        completedAt: completedAt ?? this.completedAt,
        dealTitle: dealTitle ?? this.dealTitle,
        dealPrice: dealPrice ?? this.dealPrice,
        dealImage: dealImage ?? this.dealImage,
        userName: userName ?? this.userName,
        userPhone: userPhone ?? this.userPhone,
        businessName: businessName ?? this.businessName,
        businessLatitude: businessLatitude ?? this.businessLatitude,
        businessLongitude: businessLongitude ?? this.businessLongitude,
        notes: notes ?? this.notes,
        quantity: quantity ?? this.quantity,
      );

  /// Get time since order was created
  Duration get timeSinceCreated => DateTime.now().difference(createdAt);

  /// Get display time string
  String get displayTime {
    final duration = timeSinceCreated;
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s ago';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ago';
    } else {
      return '${duration.inDays}d ago';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        dealId,
        businessId,
        status,
        createdAt,
        updatedAt,
        acceptedAt,
        readyAt,
        completedAt,
        dealTitle,
        dealPrice,
        dealImage,
        userName,
        userPhone,
        businessName,
        businessLatitude,
        businessLongitude,
        notes,
        quantity,
      ];
}
