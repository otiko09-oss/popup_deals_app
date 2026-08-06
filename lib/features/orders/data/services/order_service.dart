import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:popup_deals_app/features/orders/data/models/order_model.dart';

/// Service for managing orders/reservations
class OrderService {
  OrderService({
    FirebaseFirestore? firestore,
    Logger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? Logger();
  final FirebaseFirestore _firestore;
  final Logger _logger;

  /// Create a new order
  ///
  /// Returns the order ID
  /// Throws exception if creation fails
  Future<String> createOrder({
    required String userId,
    required String dealId,
    required String businessId,
    required String dealTitle,
    required double dealPrice,
    required String dealImage,
    required String userName,
    required String userPhone,
    required String businessName,
    required double businessLatitude,
    required double businessLongitude,
    String? notes,
    int quantity = 1,
  }) async {
    try {
      _logger.i('Creating order for deal: $dealId by user: $userId');

      final orderId = _firestore.collection('orders').doc().id;
      final now = DateTime.now();

      final orderData = OrderModel(
        id: orderId,
        userId: userId,
        dealId: dealId,
        businessId: businessId,
        status: OrderStatus.pending,
        createdAt: now,
        dealTitle: dealTitle,
        dealPrice: dealPrice,
        dealImage: dealImage,
        userName: userName,
        userPhone: userPhone,
        businessName: businessName,
        businessLatitude: businessLatitude,
        businessLongitude: businessLongitude,
        notes: notes,
        quantity: quantity,
      );

      await _firestore
          .collection('orders')
          .doc(orderId)
          .set(orderData.toJson());

      _logger.i('Order created successfully: $orderId');

      return orderId;
    } on Object catch (e) {
      _logger.e('Error creating order: $e');
      rethrow;
    }
  }

  /// Update order status
  ///
  /// Automatically sets the appropriate timestamp based on status
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
  }) async {
    try {
      _logger.i('Updating order status: $orderId to $newStatus');

      final now = DateTime.now();
      final updateData = {
        'status': newStatus.name,
        'updatedAt': now.toIso8601String(),
      };

      // Set the appropriate timestamp based on status
      switch (newStatus) {
        case OrderStatus.accepted:
          updateData['acceptedAt'] = now.toIso8601String();
          break;
        case OrderStatus.ready:
          updateData['readyAt'] = now.toIso8601String();
          break;
        case OrderStatus.completed:
          updateData['completedAt'] = now.toIso8601String();
          break;
        case OrderStatus.cancelled:
          // No special timestamp for cancelled
          break;
        case OrderStatus.pending:
          // No special timestamp for pending
          break;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);

      _logger.i('Order status updated successfully: $orderId');
    } on Object catch (e) {
      _logger.e('Error updating order status: $e');
      rethrow;
    }
  }

  /// Get an order by ID
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromJson(doc.data()!);
      }
      return null;
    } on Object catch (e) {
      _logger.e('Error fetching order: $e');
      rethrow;
    }
  }

  /// Get all orders for a specific user
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      _logger.i('Fetching orders for user: $userId');

      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data()))
          .toList();
    } on Object catch (e) {
      _logger.e('Error fetching user orders: $e');
      rethrow;
    }
  }

  /// Get real-time stream of orders for a user
  Stream<List<OrderModel>> getUserOrdersStream(String userId) => _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromJson(doc.data()))
              .toList())
          .handleError((e) {
        _logger.e('Error in user orders stream: $e');
      });

  /// Get all orders for a business (all statuses)
  Future<List<OrderModel>> getBusinessOrders(String businessId) async {
    try {
      _logger.i('Fetching orders for business: $businessId');

      final snapshot = await _firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data()))
          .toList();
    } on Object catch (e) {
      _logger.e('Error fetching business orders: $e');
      rethrow;
    }
  }

  /// Get real-time stream of all orders for a business
  Stream<List<OrderModel>> getBusinessOrdersStream(String businessId) =>
      _firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromJson(doc.data()))
              .toList())
          .handleError((e) {
        _logger.e('Error in business orders stream: $e');
      });

  /// Get pending orders for a business (real-time)
  Stream<List<OrderModel>> getBusinessPendingOrdersStream(String businessId) =>
      _firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromJson(doc.data()))
              .toList())
          .handleError((e) {
        _logger.e('Error in pending orders stream: $e');
      });

  /// Get orders for a deal (for deal analytics)
  Future<List<OrderModel>> getDealOrders(String dealId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('dealId', isEqualTo: dealId)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data()))
          .toList();
    } on Object catch (e) {
      _logger.e('Error fetching deal orders: $e');
      rethrow;
    }
  }

  /// Cancel an order
  Future<void> cancelOrder(String orderId) async {
    try {
      _logger.i('Cancelling order: $orderId');
      await updateOrderStatus(
        orderId: orderId,
        newStatus: OrderStatus.cancelled,
      );
    } on Object catch (e) {
      _logger.e('Error cancelling order: $e');
      rethrow;
    }
  }

  /// Get count of pending orders for a business
  Future<int> getPendingOrderCount(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      return snapshot.count ?? 0;
    } on Object catch (e) {
      _logger.e('Error getting pending order count: $e');
      return 0;
    }
  }

  /// Get completed orders count for a business (today)
  Future<int> getTodaysCompletedOrderCount(String businessId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .where('status', isEqualTo: 'completed')
          .where('completedAt',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('completedAt', isLessThan: endOfDay.toIso8601String())
          .count()
          .get();

      return snapshot.count ?? 0;
    } on Object catch (e) {
      _logger.e('Error getting completed order count: $e');
      return 0;
    }
  }
}
