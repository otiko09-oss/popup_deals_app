import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/review_model.dart';
import '../../data/services/review_service.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

final reviewForOrderProvider =
    FutureProvider.family<ReviewModel?, String>((ref, orderId) {
  return ref.watch(reviewServiceProvider).getReviewForOrder(orderId);
});

final businessRatingProvider =
    StreamProvider.family<BusinessRating, String>((ref, businessId) {
  return ref.watch(reviewServiceProvider).businessRatingStream(businessId);
});
