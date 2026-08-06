import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, Logger? logger})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? Logger();
  final FirebaseFirestore _firestore;
  final Logger _logger;

  /// Create a document
  Future<void> createDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      _logger.i('Creating document: $collection/$docId');
      await _firestore.collection(collection).doc(docId).set(data);
      _logger.i('Document created successfully');
    } catch (e) {
      _logger.e('Error creating document: $e');
      rethrow;
    }
  }

  /// Get a single document
  Future<DocumentSnapshot> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      _logger.i('Fetching document: $collection/$docId');
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc;
    } catch (e) {
      _logger.e('Error fetching document: $e');
      rethrow;
    }
  }

  /// Get documents from a collection with optional query
  Future<QuerySnapshot> getDocuments({
    required String collection,
    Query Function(Query)? queryBuilder,
  }) async {
    try {
      _logger.i('Fetching documents from collection: $collection');
      Query query = _firestore.collection(collection);

      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      final docs = await query.get();
      _logger.i('Fetched ${docs.docs.length} documents');
      return docs;
    } catch (e) {
      _logger.e('Error fetching documents: $e');
      rethrow;
    }
  }

  /// Get real-time stream of documents
  Stream<QuerySnapshot> getDocumentsStream({
    required String collection,
    Query Function(Query)? queryBuilder,
  }) {
    try {
      Query query = _firestore.collection(collection);

      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      return query.snapshots();
    } catch (e) {
      _logger.e('Error streaming documents: $e');
      rethrow;
    }
  }

  /// Get real-time stream of a single document
  Stream<DocumentSnapshot> getDocumentStream({
    required String collection,
    required String docId,
  }) {
    try {
      return _firestore.collection(collection).doc(docId).snapshots();
    } catch (e) {
      _logger.e('Error streaming document: $e');
      rethrow;
    }
  }

  /// Update a document
  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      _logger.i('Updating document: $collection/$docId');
      await _firestore.collection(collection).doc(docId).update(data);
      _logger.i('Document updated successfully');
    } catch (e) {
      _logger.e('Error updating document: $e');
      rethrow;
    }
  }

  /// Delete a document
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      _logger.i('Deleting document: $collection/$docId');
      await _firestore.collection(collection).doc(docId).delete();
      _logger.i('Document deleted successfully');
    } catch (e) {
      _logger.e('Error deleting document: $e');
      rethrow;
    }
  }

  /// Batch write operations
  Future<void> batchWrite(void Function(WriteBatch) updateFn) async {
    try {
      _logger.i('Performing batch write');
      final batch = _firestore.batch();
      updateFn(batch);
      await batch.commit();
      _logger.i('Batch write completed successfully');
    } catch (e) {
      _logger.e('Error during batch write: $e');
      rethrow;
    }
  }

  /// Transaction write
  Future<T> transaction<T>(
    Future<T> Function(Transaction) transactionFn,
  ) async {
    try {
      _logger.i('Performing transaction');
      final result = await _firestore.runTransaction(transactionFn);
      _logger.i('Transaction completed successfully');
      return result;
    } catch (e) {
      _logger.e('Error during transaction: $e');
      rethrow;
    }
  }

  /// Search documents
  Future<QuerySnapshot> searchDocuments({
    required String collection,
    required String field,
    required String searchTerm,
  }) async {
    try {
      _logger.i('Searching in $collection for "$searchTerm" in field "$field"');
      final query = await _firestore
          .collection(collection)
          .where(field, isGreaterThanOrEqualTo: searchTerm)
          .where(field, isLessThan: '${searchTerm}z')
          .get();
      return query;
    } catch (e) {
      _logger.e('Error searching documents: $e');
      rethrow;
    }
  }
}
