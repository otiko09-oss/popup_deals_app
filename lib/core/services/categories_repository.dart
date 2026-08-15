import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/marketplace_categories.dart';

/// Provides administrator-configured categories while keeping the app
/// usable before the optional `categories` collection has been seeded.
class CategoriesRepository {
  CategoriesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<MarketplaceCategory>> activeStream() async* {
    try {
      await for (final snapshot in _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .snapshots()) {
        final categories = snapshot.docs
            .map((doc) => MarketplaceCategory.fromJson(doc.id, doc.data()))
            .toList();
        yield categories.isEmpty ? MarketplaceCategories.all : categories;
      }
    } on FirebaseException {
      // Categories are optional configuration; the built-in list remains a
      // safe fallback during first deployment or transient connection
      // failures.
      yield MarketplaceCategories.all;
    }
  }
}