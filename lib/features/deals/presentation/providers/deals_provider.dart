import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:popup_deals_app/core/services/firestore_service.dart';
import 'package:popup_deals_app/features/deals/data/models/deal.dart';

// Firestore Service provider
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

// Deals Stream provider
final dealsProvider = StreamProvider<List<Deal>>((ref) async* {
  final firestoreService = ref.watch(firestoreServiceProvider);

  final stream = firestoreService.getDocumentsStream(
    collection: 'deals',
    queryBuilder: (query) => query
        .where('isActive', isEqualTo: true)
        .orderBy('discountPercentage', descending: true),
  );

  await for (final snapshot in stream) {
    final deals = snapshot.docs
        .map((doc) => Deal.fromJson({
              'id': doc.id,
              ...doc.data()! as Map<String, dynamic>,
            }))
        .toList();
    yield deals;
  }
});

// Search deals provider
final searchDealsProvider =
    FutureProvider.family<List<Deal>, String>((ref, query) async {
  final firestoreService = ref.watch(firestoreServiceProvider);

  final snapshot = await firestoreService.searchDocuments(
    collection: 'deals',
    field: 'title',
    searchTerm: query,
  );

  return snapshot.docs
      .map((doc) => Deal.fromJson({
            'id': doc.id,
            ...doc.data()! as Map<String, dynamic>,
          }))
      .toList();
});

// Filter deals by category
final dealsByCategoryProvider = StreamProvider.family<List<Deal>, String>(
  (ref, category) async* {
    final firestoreService = ref.watch(firestoreServiceProvider);

    final stream = firestoreService.getDocumentsStream(
      collection: 'deals',
      queryBuilder: (query) => query
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true),
    );

    await for (final snapshot in stream) {
      final deals = snapshot.docs
          .map((doc) => Deal.fromJson({
                'id': doc.id,
                ...doc.data()! as Map<String, dynamic>,
              }))
          .toList();
      yield deals;
    }
  },
);

// Single deal provider
final dealProvider = FutureProvider.family<Deal?, String>((ref, dealId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);

  final doc = await firestoreService.getDocument(
    collection: 'deals',
    docId: dealId,
  );

  if (!doc.exists) return null;

  return Deal.fromJson({
    'id': doc.id,
    ...doc.data()! as Map<String, dynamic>,
  });
});
