import 'package:equatable/equatable.dart';

class Deal extends Equatable {
  const Deal({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercentage,
    required this.category,
    required this.restaurant,
    required this.restaurantId,
    required this.startTime,
    required this.endTime,
    required this.expiresAt,
    required this.createdAt,
    required this.isActive,
    required this.likes,
    required this.redeemed,
    required this.tags,
    required this.latitude,
    required this.longitude,
    this.restaurantPhoneNumber,
    this.restaurantAddress,
  });

  factory Deal.fromJson(Map<String, dynamic> json) => Deal(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        imageUrl: json['imageUrl'] as String,
        originalPrice: (json['originalPrice'] as num).toDouble(),
        discountedPrice: (json['discountedPrice'] as num).toDouble(),
        discountPercentage: json['discountPercentage'] as int,
        category: json['category'] as String,
        restaurant: json['restaurant'] as String,
        restaurantId: json['restaurantId'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        isActive: json['isActive'] as bool,
        likes: json['likes'] as int,
        redeemed: json['redeemed'] as int,
        tags: List<String>.from(json['tags'] as List),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        restaurantPhoneNumber: json['restaurantPhoneNumber'] as String?,
        restaurantAddress: json['restaurantAddress'] as String?,
      );
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double originalPrice;
  final double discountedPrice;
  final int discountPercentage;
  final String category;
  final String restaurant;
  final String restaurantId;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime expiresAt;
  final DateTime createdAt;
  final bool isActive;
  final int likes;
  final int redeemed;
  final List<String> tags;
  final double latitude;
  final double longitude;
  final String? restaurantPhoneNumber;
  final String? restaurantAddress;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'originalPrice': originalPrice,
        'discountedPrice': discountedPrice,
        'discountPercentage': discountPercentage,
        'category': category,
        'restaurant': restaurant,
        'restaurantId': restaurantId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
        'likes': likes,
        'redeemed': redeemed,
        'tags': tags,
        'latitude': latitude,
        'longitude': longitude,
        'restaurantPhoneNumber': restaurantPhoneNumber,
        'restaurantAddress': restaurantAddress,
      };

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        originalPrice,
        discountedPrice,
        discountPercentage,
        category,
        restaurant,
        restaurantId,
        startTime,
        endTime,
        expiresAt,
        createdAt,
        isActive,
        likes,
        redeemed,
        tags,
        latitude,
        longitude,
        restaurantPhoneNumber,
        restaurantAddress,
      ];
}
