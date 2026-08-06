import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import '../models/deal_creation_form.dart';

class DealCreationService {
  DealCreationService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Logger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _logger = logger ?? Logger();
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Logger _logger;

  /// Upload deal image to Firebase Storage and return the URL
  ///
  /// Returns the download URL of the uploaded image
  /// Throws exception if upload fails
  Future<String> uploadDealImage({
    required File imageFile,
    required String businessId,
  }) async {
    try {
      _logger.i('Starting image upload for business: $businessId');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'deals/$businessId/${timestamp}_deal_image.jpg';

      final ref = _storage.ref().child(fileName);

      // Upload with metadata
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'businessId': businessId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      _logger.i('Image uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      _logger.e('Error uploading deal image: $e');
      rethrow;
    }
  }

  /// Create a new deal and save it to Firestore
  ///
  /// Returns the created deal ID
  /// Throws exception if creation fails
  Future<String> createDeal({
    required DealCreationForm form,
    required String businessId,
    required String restaurantName,
  }) async {
    try {
      _logger.i('Creating deal for business: $businessId');

      // Validate form
      final validationError = form.validate();
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Upload image
      final imageUrl = await uploadDealImage(
        imageFile: form.imageFile!,
        businessId: businessId,
      );

      // Generate deal ID
      final dealId = _firestore.collection('deals').doc().id;

      // Prepare deal data
      final dealData = {
        'id': dealId,
        'title': form.title.trim(),
        'description': form.description.trim(),
        'imageUrl': imageUrl,
        'originalPrice': form.oldPrice,
        'discountedPrice': form.newPrice,
        'discountPercentage': form.discountPercentage,
        'category': form.category,
        'restaurant': restaurantName,
        'restaurantId': businessId,
        'startTime': form.startTime.toIso8601String(),
        'endTime': form.endTime.toIso8601String(),
        'expiresAt': form.endTime.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
        'likes': 0,
        'redeemed': 0,
        'tags': form.tags,
        'latitude': form.latitude,
        'longitude': form.longitude,
      };

      // Save to Firestore
      await _firestore.collection('deals').doc(dealId).set(dealData);

      _logger.i('Deal created successfully: $dealId');

      return dealId;
    } catch (e) {
      _logger.e('Error creating deal: $e');
      rethrow;
    }
  }

  /// Update an existing deal
  ///
  /// Returns the updated deal ID
  /// Throws exception if update fails
  Future<String> updateDeal({
    required String dealId,
    required DealCreationForm form,
    required String businessId,
    required String restaurantName,
    String? existingImageUrl,
  }) async {
    try {
      _logger.i('Updating deal: $dealId');

      // Validate form (an existing image satisfies the image requirement)
      final validationError =
          form.validate(requireImage: existingImageUrl == null);
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Upload new image if provided, otherwise use existing
      late final String imageUrl;
      if (form.imageFile != null) {
        imageUrl = await uploadDealImage(
          imageFile: form.imageFile!,
          businessId: businessId,
        );
      } else if (existingImageUrl != null) {
        imageUrl = existingImageUrl;
      } else {
        throw Exception('Deal image is required');
      }

      // Prepare update data
      final updateData = {
        'title': form.title.trim(),
        'description': form.description.trim(),
        'imageUrl': imageUrl,
        'originalPrice': form.oldPrice,
        'discountedPrice': form.newPrice,
        'discountPercentage': form.discountPercentage,
        'category': form.category,
        'restaurant': restaurantName,
        'startTime': form.startTime.toIso8601String(),
        'endTime': form.endTime.toIso8601String(),
        'expiresAt': form.endTime.toIso8601String(),
        'tags': form.tags,
        'latitude': form.latitude,
        'longitude': form.longitude,
      };

      // Update in Firestore
      await _firestore.collection('deals').doc(dealId).update(updateData);

      _logger.i('Deal updated successfully: $dealId');

      return dealId;
    } catch (e) {
      _logger.e('Error updating deal: $e');
      rethrow;
    }
  }

  /// Delete a deal
  Future<void> deleteDeal(String dealId) async {
    try {
      _logger.i('Deleting deal: $dealId');
      await _firestore.collection('deals').doc(dealId).delete();
      _logger.i('Deal deleted successfully: $dealId');
    } catch (e) {
      _logger.e('Error deleting deal: $e');
      rethrow;
    }
  }

  /// Get a deal by ID
  Future<Map<String, dynamic>?> getDeal(String dealId) async {
    try {
      final doc = await _firestore.collection('deals').doc(dealId).get();
      return doc.data();
    } catch (e) {
      _logger.e('Error fetching deal: $e');
      rethrow;
    }
  }

  /// Get all deals for a business
  Future<List<Map<String, dynamic>>> getBusinessDeals(String businessId) async {
    try {
      _logger.i('Fetching deals for business: $businessId');

      final snapshot = await _firestore
          .collection('deals')
          .where('restaurantId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _logger.e('Error fetching business deals: $e');
      rethrow;
    }
  }

  /// Get real-time stream of deals for a business
  Stream<List<Map<String, dynamic>>> getBusinessDealsStream(
          String businessId) =>
      _firestore
          .collection('deals')
          .where('restaurantId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
          .handleError((e) {
        _logger.e('Error in business deals stream: $e');
      });

  /// Deactivate a deal (mark as inactive)
  Future<void> deactivateDeal(String dealId) async {
    try {
      _logger.i('Deactivating deal: $dealId');
      await _firestore
          .collection('deals')
          .doc(dealId)
          .update({'isActive': false});
      _logger.i('Deal deactivated successfully: $dealId');
    } catch (e) {
      _logger.e('Error deactivating deal: $e');
      rethrow;
    }
  }

  /// Reactivate a deal (mark as active)
  Future<void> reactivateDeal(String dealId) async {
    try {
      _logger.i('Reactivating deal: $dealId');
      await _firestore
          .collection('deals')
          .doc(dealId)
          .update({'isActive': true});
      _logger.i('Deal reactivated successfully: $dealId');
    } catch (e) {
      _logger.e('Error reactivating deal: $e');
      rethrow;
    }
  }
}
