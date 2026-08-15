import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/marketplace_categories.dart';
import '../services/categories_repository.dart';

final categoriesRepositoryProvider =
    Provider<CategoriesRepository>((ref) => CategoriesRepository());

/// Admin-configurable marketplace categories, live from Firestore. Falls
/// back to the hardcoded [MarketplaceCategories.all] list automatically
/// (inside the repository) whenever the `categories` collection hasn't
/// been seeded yet.
final activeCategoriesProvider =
    StreamProvider<List<MarketplaceCategory>>((ref) {
  return ref.watch(categoriesRepositoryProvider).activeStream();
});
