import 'package:equatable/equatable.dart';

/// BusinessModel represents a business/restaurant account in the app
class BusinessModel extends Equatable {
  // List of deal IDs

  const BusinessModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.createdAt,
    this.status = 'pending',
    this.logoUrl,
    this.updatedAt,
    this.activeDeals = const [],
  });

  /// Create BusinessModel from Firestore JSON
  factory BusinessModel.fromJson(Map<String, dynamic> json) => BusinessModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
        logoUrl: json['logoUrl'] as String?,
        description: json['description'] as String? ?? '',
        address: json['address'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        category: json['category'] as String? ?? '',
        // Backward-compatible with older documents that only had
        // isVerified: true/false instead of a status string.
        status: json['status'] as String? ??
            (json['isVerified'] == true ? 'approved' : 'pending'),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        activeDeals: List<String>.from(json['activeDeals'] as List? ?? []),
      );
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? logoUrl;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String category; // e.g., "Pizza", "Burgers", "Coffee"

  /// One of: pending | approved | rejected | suspended.
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> activeDeals;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';

  /// Kept for any code (or old cached UI state) still checking a simple
  /// verified flag — true only once an admin has approved the business.
  bool get isVerified => status == 'approved';

  /// Convert BusinessModel to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'logoUrl': logoUrl,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'activeDeals': activeDeals,
      };

  /// Create a copy of BusinessModel with optional field replacements
  BusinessModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? logoUrl,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? category,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? activeDeals,
  }) =>
      BusinessModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        logoUrl: logoUrl ?? this.logoUrl,
        description: description ?? this.description,
        address: address ?? this.address,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        category: category ?? this.category,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        activeDeals: activeDeals ?? this.activeDeals,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phoneNumber,
        logoUrl,
        description,
        address,
        latitude,
        longitude,
        category,
        status,
        createdAt,
        updatedAt,
        activeDeals,
      ];
}
