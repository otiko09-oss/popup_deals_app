/// Global marketplace categories for Popup Deals B2B2C platform.
class MarketplaceCategory {
  const MarketplaceCategory({
    required this.id,
    required this.labelEn,
    required this.labelKa,
    required this.emoji,
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// Reads a category document from the `categories` Firestore collection
  /// — see CategoriesRepository. [docId] is used as the category id.
  factory MarketplaceCategory.fromJson(
    String docId,
    Map<String, dynamic> json,
  ) =>
      MarketplaceCategory(
        id: docId,
        labelEn: json['labelEn'] as String? ?? docId,
        labelKa: json['labelKa'] as String? ?? docId,
        emoji: json['emoji'] as String? ?? '🏷️',
        isActive: json['isActive'] as bool? ?? true,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  final String id;
  final String labelEn;
  final String labelKa;
  final String emoji;
  final bool isActive;
  final int sortOrder;

  String label(String locale) => locale == 'ka' ? labelKa : labelEn;

  Map<String, dynamic> toJson() => {
        'labelEn': labelEn,
        'labelKa': labelKa,
        'emoji': emoji,
        'isActive': isActive,
        'sortOrder': sortOrder,
      };
}

class MarketplaceCategories {
  static const List<MarketplaceCategory> all = [
    MarketplaceCategory(
      id: 'food',
      labelEn: 'Food',
      labelKa: 'კვება',
      emoji: '🍽️',
    ),
    MarketplaceCategory(
      id: 'hotels',
      labelEn: 'Hotels',
      labelKa: 'სასტუმროები',
      emoji: '🏨',
    ),
    MarketplaceCategory(
      id: 'beauty',
      labelEn: 'Beauty',
      labelKa: 'სილამაზე',
      emoji: '💅',
    ),
    MarketplaceCategory(
      id: 'fitness',
      labelEn: 'Fitness',
      labelKa: 'ფიტნესი',
      emoji: '💪',
    ),
    MarketplaceCategory(
      id: 'shopping',
      labelEn: 'Shopping',
      labelKa: 'შოპინგი',
      emoji: '🛍️',
    ),
    MarketplaceCategory(
      id: 'entertainment',
      labelEn: 'Entertainment',
      labelKa: 'გართობა',
      emoji: '🎬',
    ),
    MarketplaceCategory(
      id: 'services',
      labelEn: 'Services',
      labelKa: 'სერვისები',
      emoji: '🔧',
    ),
  ];

  static List<String> get ids => all.map((c) => c.id).toList();

  static MarketplaceCategory? byId(String id) {
    for (final category in all) {
      if (category.id == id) return category;
    }
    return null;
  }
}
