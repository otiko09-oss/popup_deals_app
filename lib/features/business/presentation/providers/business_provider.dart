import 'package:riverpod/riverpod.dart';
import '../../data/models/deal_creation_form.dart';
import '../../data/services/deal_creation_service.dart';

/// Singleton provider for DealCreationService
final dealCreationServiceProvider =
    Provider<DealCreationService>((ref) => DealCreationService());

/// State for deal creation operation
class DealCreationState {
  DealCreationState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.createdDealId,
  });
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final String? createdDealId;

  DealCreationState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    String? createdDealId,
  }) =>
      DealCreationState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        successMessage: successMessage,
        createdDealId: createdDealId ?? this.createdDealId,
      );

  /// Clear messages while keeping loading state
  DealCreationState clearMessages() => DealCreationState(
        isLoading: isLoading,
        createdDealId: createdDealId,
      );
}

/// StateNotifier for managing deal creation state
class DealCreationNotifier extends StateNotifier<DealCreationState> {
  DealCreationNotifier(this._dealCreationService) : super(DealCreationState());
  final DealCreationService _dealCreationService;

  /// Create a new deal
  Future<void> createDeal({
    required DealCreationForm form,
    required String businessId,
    required String restaurantName,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      // Validate form
      final validationError = form.validate();
      if (validationError != null) {
        state = state.copyWith(
          isLoading: false,
          error: validationError,
        );
        return;
      }

      // Create deal
      final dealId = await _dealCreationService.createDeal(
        form: form,
        businessId: businessId,
        restaurantName: restaurantName,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Deal created successfully!',
        createdDealId: dealId,
      );
    } on Object catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create deal: ${e.toString()}',
      );
    }
  }

  /// Update an existing deal
  Future<void> updateDeal({
    required String dealId,
    required DealCreationForm form,
    required String businessId,
    required String restaurantName,
    String? existingImageUrl,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      // Validate form (existing image satisfies the image requirement)
      final validationError =
          form.validate(requireImage: existingImageUrl == null);
      if (validationError != null) {
        state = state.copyWith(
          isLoading: false,
          error: validationError,
        );
        return;
      }

      // Update deal
      await _dealCreationService.updateDeal(
        dealId: dealId,
        form: form,
        businessId: businessId,
        restaurantName: restaurantName,
        existingImageUrl: existingImageUrl,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Deal updated successfully!',
      );
    } on Object catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update deal: ${e.toString()}',
      );
    }
  }

  /// Clear all messages
  void clearMessages() {
    state = state.clearMessages();
  }

  /// Reset to initial state
  void reset() {
    state = DealCreationState();
  }
}

/// StateNotifier provider for deal creation
final dealCreationProvider =
    StateNotifierProvider<DealCreationNotifier, DealCreationState>((ref) {
  final service = ref.watch(dealCreationServiceProvider);
  return DealCreationNotifier(service);
});

/// Get all deals for a specific business
final businessDealsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, businessId) async {
  final service = ref.watch(dealCreationServiceProvider);
  return service.getBusinessDeals(businessId);
});

/// Get real-time stream of deals for a specific business
final businessDealsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, businessId) {
  final service = ref.watch(dealCreationServiceProvider);
  return service.getBusinessDealsStream(businessId);
});

/// Get a single deal by ID
final dealProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, dealId) async {
  final service = ref.watch(dealCreationServiceProvider);
  return service.getDeal(dealId);
});

/// Deal deactivation state provider
class DealToggleState {
  DealToggleState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });
  final bool isLoading;
  final String? error;
  final String? successMessage;

  DealToggleState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) =>
      DealToggleState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        successMessage: successMessage,
      );

  DealToggleState clearMessages() => DealToggleState(isLoading: isLoading);
}

/// StateNotifier for toggling deal active/inactive status
class DealToggleNotifier extends StateNotifier<DealToggleState> {
  DealToggleNotifier(this._dealCreationService) : super(DealToggleState());
  final DealCreationService _dealCreationService;

  Future<void> toggleDeal(String dealId,
      {required bool currentlyActive}) async {
    state = state.copyWith(isLoading: true);

    try {
      if (currentlyActive) {
        await _dealCreationService.deactivateDeal(dealId);
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Deal deactivated',
        );
      } else {
        await _dealCreationService.reactivateDeal(dealId);
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Deal reactivated',
        );
      }
    } on Object catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to toggle deal: ${e.toString()}',
      );
    }
  }

  void clearMessages() {
    state = state.clearMessages();
  }
}

/// Provider for toggling deal status
final dealToggleProvider =
    StateNotifierProvider<DealToggleNotifier, DealToggleState>((ref) {
  final service = ref.watch(dealCreationServiceProvider);
  return DealToggleNotifier(service);
});
