import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    required this.userType,
    required this.createdAt,
    required this.lastSignIn,
    required this.isVerified,
    required this.favorites,
    this.displayName,
    this.photoUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        userType: json['userType'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastSignIn: DateTime.parse(json['lastSignIn'] as String),
        isVerified: json['isVerified'] as bool,
        favorites: List<String>.from(json['favorites'] as List? ?? []),
      );
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String userType; // 'customer' or 'restaurant'
  final DateTime createdAt;
  final DateTime lastSignIn;
  final bool isVerified;
  final List<String> favorites;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'userType': userType,
        'createdAt': createdAt.toIso8601String(),
        'lastSignIn': lastSignIn.toIso8601String(),
        'isVerified': isVerified,
        'favorites': favorites,
      };

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? userType,
    DateTime? createdAt,
    DateTime? lastSignIn,
    bool? isVerified,
    List<String>? favorites,
  }) =>
      AppUser(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        userType: userType ?? this.userType,
        createdAt: createdAt ?? this.createdAt,
        lastSignIn: lastSignIn ?? this.lastSignIn,
        isVerified: isVerified ?? this.isVerified,
        favorites: favorites ?? this.favorites,
      );

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        userType,
        createdAt,
        lastSignIn,
        isVerified,
        favorites,
      ];
}
