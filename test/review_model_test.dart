import 'package:flutter_test/flutter_test.dart';
import 'package:popup_deals_app/features/reviews/data/models/review_model.dart';

void main() {
  test('ReviewModel parses a completed-order review', () {
    final now = DateTime(2026, 10, 24).toIso8601String();
    final review = ReviewModel.fromJson({
      'id': 'order_1',
      'orderId': 'order_1',
      'userId': 'user_1',
      'userName': 'Nino',
      'businessId': 'business_1',
      'dealId': 'deal_1',
      'rating': 5,
      'comment': 'Great offer',
      'createdAt': now,
      'updatedAt': now,
    });

    expect(review.rating, 5);
    expect(review.comment, 'Great offer');
  });

  test('BusinessRating defaults safely for businesses without reviews', () {
    expect(BusinessRating.fromJson(null), const BusinessRating(average: 0, count: 0));
  });
}
