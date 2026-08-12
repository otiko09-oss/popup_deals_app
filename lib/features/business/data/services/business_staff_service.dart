import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

/// Manages business_staff/{staffUid} records — the mechanism that lets a
/// business owner grant a teammate (e.g. a cashier) permission to scan and
/// redeem QR codes on the business's behalf, without sharing the owner's
/// login.
class BusinessStaffService {
  BusinessStaffService({
    FirebaseFirestore? firestore,
    Logger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? Logger();

  final FirebaseFirestore _firestore;
  final Logger _logger;

  /// Grants [staffUid] staff access to [businessId]. The staff member must
  /// already have a Popup Deals account (they sign up normally first, then
  /// the owner adds their uid here). Only the business owner can call this
  /// successfully — enforced by firestore.rules, not just this method.
  Future<void> addStaff({
    required String businessId,
    required String staffUid,
    String? displayName,
  }) async {
    await _firestore.collection('business_staff').doc(staffUid).set({
      'businessId': businessId,
      'displayName': displayName,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
    });
    _logger.i('Added staff $staffUid to business $businessId');
  }

  /// Revokes access without deleting history — flips isActive to false.
  Future<void> deactivateStaff(String staffUid) async {
    await _firestore.collection('business_staff').doc(staffUid).update({
      'isActive': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> reactivateStaff(String staffUid) async {
    await _firestore.collection('business_staff').doc(staffUid).update({
      'isActive': true,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeStaff(String staffUid) async {
    await _firestore.collection('business_staff').doc(staffUid).delete();
  }

  /// All staff (active and inactive) for a business, owner-only read.
  Stream<List<Map<String, dynamic>>> staffStream(String businessId) =>
      _firestore
          .collection('business_staff')
          .where('businessId', isEqualTo: businessId)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  /// Resolves which business the signed-in [uid] can act for right now:
  /// - if they own a business (businesses/{uid} exists), that's their own id
  /// - else, if they're an active staff member, returns that business's id
  /// - else, null (not associated with any business)
  Future<String?> resolveActingBusinessId(String uid) async {
    final ownBusiness =
        await _firestore.collection('businesses').doc(uid).get();
    if (ownBusiness.exists) return uid;

    final staffDoc =
        await _firestore.collection('business_staff').doc(uid).get();
    if (staffDoc.exists && staffDoc.data()?['isActive'] == true) {
      return staffDoc.data()?['businessId'] as String?;
    }
    return null;
  }
}
