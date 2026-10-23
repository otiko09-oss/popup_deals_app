import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/review_model.dart';

class ReviewService {
  ReviewService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Future<ReviewModel> submitReview({
    required String orderId,
    required int rating,
    String comment = '',
  }) async {
    final result = await _functions.httpsCallable('submitReview').call<
        Map<String, dynamic>>({
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
    });
    final review = result.data['review'];
    if (review is! Map) {
      throw StateError('Review response was incomplete.');
    }
    return ReviewModel.fromJson(Map<String, dynamic>.from(review));
  }

  Future<ReviewModel?> getReviewForOrder(String orderId) async {
    final doc = await _firestore.collection('reviews').doc(orderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ReviewModel.fromJson(doc.data()!);
  }

  Stream<BusinessRating> businessRatingStream(String businessId) => _firestore
      .collection('businesses')
      .doc(businessId)
      .snapshots()
      .map((doc) => BusinessRating.fromJson(doc.data()));
}
