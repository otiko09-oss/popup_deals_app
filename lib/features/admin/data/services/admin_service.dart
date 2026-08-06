import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class AdminService {
  AdminService({
    FirebaseFirestore? firestore,
    Logger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? Logger();

  final FirebaseFirestore _firestore;
  final Logger _logger;

  Future<Map<String, int>> getPlatformStats() async {
    final users = await _firestore.collection('users').count().get();
    final businesses = await _firestore.collection('businesses').count().get();
    final deals = await _firestore.collection('deals').count().get();
    final redemptions =
        await _firestore.collection('redemptions').count().get();

    return {
      'users': users.count ?? 0,
      'businesses': businesses.count ?? 0,
      'deals': deals.count ?? 0,
      'redemptions': redemptions.count ?? 0,
    };
  }

  Stream<List<Map<String, dynamic>>> usersStream() => _firestore
      .collection('users')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> businessesStream() => _firestore
      .collection('businesses')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> pendingDealsStream() => _firestore
      .collection('deals')
      .where('moderationStatus', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> setUserBlocked(String userId, {required bool blocked}) async {
    await _firestore.collection('users').doc(userId).update({
      'isBlocked': blocked,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    _logger.i('User $userId blocked=$blocked');
  }

  Future<void> setBusinessVerified(String businessId,
      {required bool verified}) async {
    await _firestore.collection('businesses').doc(businessId).update({
      'isVerified': verified,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> moderateDeal({
    required String dealId,
    required String status, // approved | rejected
  }) async {
    await _firestore.collection('deals').doc(dealId).update({
      'moderationStatus': status,
      'isActive': status == 'approved',
      'moderatedAt': DateTime.now().toIso8601String(),
    });
  }
}
