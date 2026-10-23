import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.businessId,
    required this.dealId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String? ?? '',
        orderId: json['orderId'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? 'Customer',
        businessId: json['businessId'] as String? ?? '',
        dealId: json['dealId'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        comment: json['comment'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );

  final String id;
  final String orderId;
  final String userId;
  final String userName;
  final String businessId;
  final String dealId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object> get props => [
        id,
        orderId,
        userId,
        userName,
        businessId,
        dealId,
        rating,
        comment,
        createdAt,
        updatedAt,
      ];
}

class BusinessRating extends Equatable {
  const BusinessRating({required this.average, required this.count});

  factory BusinessRating.fromJson(Map<String, dynamic>? json) => BusinessRating(
        average: (json?['ratingAverage'] as num?)?.toDouble() ?? 0,
        count: (json?['ratingCount'] as num?)?.toInt() ?? 0,
      );

  final double average;
  final int count;

  @override
  List<Object> get props => [average, count];
}
