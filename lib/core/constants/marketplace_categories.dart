/// Global marketplace categories for Popup Deals B2B2C platform.
class MarketplaceCategory {
  const MarketplaceCategory({
    required this.id,
    required this.labelEn,
    required this.labelKa,
    required this.emoji,
  });

  final String id;
  final String labelEn;
  final String labelKa;
  final String emoji;

  String label(String locale) => locale == 'ka' ? labelKa : labelEn;
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
