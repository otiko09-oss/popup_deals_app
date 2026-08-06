import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:popup_deals_app/features/orders/data/models/order_model.dart';
import 'package:popup_deals_app/features/orders/data/services/order_service.dart';
import 'package:popup_deals_app/features/redemption/data/models/redemption_model.dart';
import 'package:popup_deals_app/features/redemption/data/services/redemption_service.dart';

/// Singleton provider for OrderService
final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

/// State for order creation
class OrderCreationState {
  OrderCreationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.createdOrderId,
    this.createdRedemption,
  });
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final String? createdOrderId;
  final RedemptionModel? createdRedemption;

  OrderCreationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    String? createdOrderId,
    RedemptionModel? createdRedemption,
  }) =>
      OrderCreationState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        successMessage: successMessage,
        createdOrderId: createdOrderId ?? this.createdOrderId,
        createdRedemption: createdRedemption ?? this.createdRedemption,
      );

  OrderCreationState clearMessages() => OrderCreationState(
        isLoading: isLoading,
        createdOrderId: createdOrderId,
        createdRedemption: createdRedemption,
      );
}

/// StateNotifier for managing order creation
class OrderCreationNotifier extends StateNotifier<OrderCreationState> {
  OrderCreationNotifier(this._orderService, this._redemptionService)
      : super(OrderCreationState());
  final OrderService _orderService;
  final RedemptionService _redemptionService;

  /// Create a new order
  Future<void> createOrder({
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
    state = state.copyWith(isLoading: true);

    try {
      final orderId = await _orderService.createOrder(
        userId: userId,
        dealId: dealId,
        businessId: businessId,
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

      final redemption = await _redemptionService.createRedemption(
        orderId: orderId,
        dealId: dealId,
        userId: userId,
        businessId: businessId,
        dealTitle: dealTitle,
        businessName: businessName,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Deal claimed! Show your QR code at the business.',
        createdOrderId: orderId,
        createdRedemption: redemption,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create reservation: ${e.toString()}',
      );
    }
  }

  void clearMessages() {
    state = state.clearMessages();
  }

  void reset() {
    state = OrderCreationState();
  }
}

/// Provider for order creation
final orderCreationProvider =
    StateNotifierProvider<OrderCreationNotifier, OrderCreationState>((ref) {
  final service = ref.watch(orderServiceProvider);
  final redemptionService = RedemptionService();
  return OrderCreationNotifier(service, redemptionService);
});

/// State for order status updates
class OrderStatusUpdateState {
  OrderStatusUpdateState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });
  final bool isLoading;
  final String? error;
  final String? successMessage;

  OrderStatusUpdateState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) =>
      OrderStatusUpdateState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        successMessage: successMessage,
      );

  OrderStatusUpdateState clearMessages() =>
      OrderStatusUpdateState(isLoading: isLoading);
}

/// StateNotifier for updating order status
class OrderStatusUpdateNotifier extends StateNotifier<OrderStatusUpdateState> {
  OrderStatusUpdateNotifier(this._orderService)
      : super(OrderStatusUpdateState());
  final OrderService _orderService;

  /// Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _orderService.updateOrderStatus(
        orderId: orderId,
        newStatus: newStatus,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Order status updated to ${newStatus.displayName}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update order: ${e.toString()}',
      );
    }
  }

  void clearMessages() {
    state = state.clearMessages();
  }
}

/// Provider for order status updates
final orderStatusUpdateProvider =
    StateNotifierProvider<OrderStatusUpdateNotifier, OrderStatusUpdateState>(
        (ref) {
  final service = ref.watch(orderServiceProvider);
  return OrderStatusUpdateNotifier(service);
});

/// Get user orders (real-time stream)
final userOrdersStreamProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, userId) {
  final service = ref.watch(orderServiceProvider);
  return service.getUserOrdersStream(userId);
});

/// Get business orders (real-time stream)
final businessOrdersStreamProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, businessId) {
  final service = ref.watch(orderServiceProvider);
  return service.getBusinessOrdersStream(businessId);
});

/// Get pending orders for business (real-time stream)
final businessPendingOrdersStreamProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, businessId) {
  final service = ref.watch(orderServiceProvider);
  return service.getBusinessPendingOrdersStream(businessId);
});

/// Get single order by ID
final orderProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final service = ref.watch(orderServiceProvider);
  return service.getOrder(orderId);
});

/// Get pending order count for business
final pendingOrderCountProvider =
    FutureProvider.family<int, String>((ref, businessId) async {
  final service = ref.watch(orderServiceProvider);
  return service.getPendingOrderCount(businessId);
});

/// Get count of orders completed today for a business
final todaysCompletedOrderCountProvider =
    FutureProvider.family<int, String>((ref, businessId) async {
  final service = ref.watch(orderServiceProvider);
  return service.getTodaysCompletedOrderCount(businessId);
});

/// Get deal orders
final dealOrdersProvider =
    FutureProvider.family<List<OrderModel>, String>((ref, dealId) async {
  final service = ref.watch(orderServiceProvider);
  return service.getDealOrders(dealId);
});
