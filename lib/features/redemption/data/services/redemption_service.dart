import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../models/redemption_model.dart';

class RedemptionService {
  RedemptionService({
    FirebaseFirestore? firestore,
    Logger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? Logger();

  final FirebaseFirestore _firestore;
  final Logger _logger;
  final Uuid _uuid = const Uuid();

  /// Creates a QR redemption record when a customer claims a deal.
  Future<RedemptionModel> createRedemption({
    required String orderId,
    required String dealId,
    required String userId,
    required String businessId,
    required String dealTitle,
    required String businessName,
    Duration validity = const Duration(hours: 24),
  }) async {
    final redemptionId = _firestore.collection('redemptions').doc().id;
    final qrPayload = 'popupdeals://redeem/$redemptionId';
    final now = DateTime.now();

    final redemption = RedemptionModel(
      id: redemptionId,
      orderId: orderId,
      dealId: dealId,
      userId: userId,
      businessId: businessId,
      qrPayload: qrPayload,
      status: RedemptionStatus.pending,
      createdAt: now,
      expiresAt: now.add(validity),
      dealTitle: dealTitle,
      businessName: businessName,
    );

    await _firestore
        .collection('redemptions')
        .doc(redemptionId)
        .set(redemption.toJson());

    await _firestore.collection('orders').doc(orderId).update({
      'redemptionId': redemptionId,
      'qrPayload': qrPayload,
    });

    _logger.i('Redemption created: $redemptionId');
    return redemption;
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
    final docRef = _firestore.collection('redemptions').doc(redemptionId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Redemption not found');
      }

      final redemption = RedemptionModel.fromJson(snapshot.data()!);

      if (redemption.businessId != businessId) {
        throw Exception('This deal belongs to another business');
      }
      if (redemption.status == RedemptionStatus.redeemed) {
        throw Exception('Already redeemed');
      }
      if (redemption.status == RedemptionStatus.expired ||
          DateTime.now().isAfter(redemption.expiresAt)) {
        transaction.update(docRef, {'status': RedemptionStatus.expired.name});
        throw Exception('QR code has expired');
      }

      final now = DateTime.now();
      transaction.update(docRef, {
        'status': RedemptionStatus.redeemed.name,
        'redeemedAt': now.toIso8601String(),
      });

      final dealRef = _firestore.collection('deals').doc(redemption.dealId);
      transaction.update(dealRef, {
        'redeemed': FieldValue.increment(1),
      });

      if (redemption.orderId.isNotEmpty) {
        final orderRef =
            _firestore.collection('orders').doc(redemption.orderId);
        transaction.update(orderRef, {
          'status': 'completed',
          'completedAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });
      }

      return redemption.copyWith(
        status: RedemptionStatus.redeemed,
        redeemedAt: now,
      );
    });
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

extension _RedemptionCopy on RedemptionModel {
  RedemptionModel copyWith({
    RedemptionStatus? status,
    DateTime? redeemedAt,
  }) =>
      RedemptionModel(
        id: id,
        orderId: orderId,
        dealId: dealId,
        userId: userId,
        businessId: businessId,
        qrPayload: qrPayload,
        status: status ?? this.status,
        createdAt: createdAt,
        expiresAt: expiresAt,
        redeemedAt: redeemedAt ?? this.redeemedAt,
        dealTitle: dealTitle,
        businessName: businessName,
      );
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
