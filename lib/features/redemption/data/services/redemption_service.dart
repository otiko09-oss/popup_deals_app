import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/redemption_model.dart';

class RedemptionService {
  RedemptionService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  /// Claims a deal through the backend, which snapshots trusted deal and
  /// business data and creates the order + QR record atomically.
  Future<ReservationResult> createReservation({
    required String dealId,
    int quantity = 1,
    String? notes,
  }) async {
    final result = await _functions.httpsCallable('createReservation').call<
        Map<String, dynamic>>({
      'dealId': dealId,
      'quantity': quantity,
      if (notes != null) 'notes': notes,
    });
    final orderId = result.data['orderId'] as String?;
    final redemption = result.data['redemption'];
    if (orderId == null || redemption is! Map) {
      throw StateError('Reservation response was incomplete.');
    }
    return ReservationResult(
      orderId: orderId,
      redemption: RedemptionModel.fromJson(Map<String, dynamic>.from(redemption)),
    );
  }

  Future<RedemptionModel?> getRedemption(String redemptionId) async {
    final doc =
        await _firestore.collection('redemptions').doc(redemptionId).get();
    if (!doc.exists || doc.data() == null) return null;
    return RedemptionModel.fromJson(doc.data()!);
  }

  /// Business scans QR and validates redemption.
  Future<RedemptionModel> redeem({
    required String redemptionId,
    required String businessId,
  }) async {
    final result = await _functions.httpsCallable('redeemReservation').call<
        Map<String, dynamic>>({'redemptionId': redemptionId});
    final redemption = result.data['redemption'];
    if (redemption is! Map) throw StateError('Redemption response was incomplete.');
    return RedemptionModel.fromJson(Map<String, dynamic>.from(redemption));
  }

  Stream<List<RedemptionModel>> getUserRedemptionsStream(String userId) =>
      _firestore
          .collection('redemptions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => RedemptionModel.fromJson(doc.data()))
              .toList());
}

class ReservationResult {
  const ReservationResult({required this.orderId, required this.redemption});
  final String orderId;
  final RedemptionModel redemption;
}

/// Parses QR payload from scanner or deep link.
String? parseRedemptionIdFromPayload(String payload) {
  final trimmed = payload.trim();
  const prefix = 'popupdeals://redeem/';
  if (trimmed.startsWith(prefix)) {
    return trimmed.substring(prefix.length);
  }
  if (trimmed.length >= 8 && !trimmed.contains('://')) {
    return trimmed;
  }
  return null;
}
