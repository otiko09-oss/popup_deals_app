import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

class StorageService {
  StorageService({FirebaseStorage? storage, Logger? logger})
      : _storage = storage ?? FirebaseStorage.instance,
        _logger = logger ?? Logger();
  final FirebaseStorage _storage;
  final Logger _logger;

  /// Upload file to storage
  Future<String> uploadFile({required File file, required String path}) async {
    try {
      _logger.i('Uploading file to: $path');
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'application/octet-stream'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      _logger.i('File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('Error uploading file: $e');
      rethrow;
    }
  }

  /// Upload bytes to storage
  Future<String> uploadBytes({
    required List<int> bytes,
    required String path,
    String? mimeType,
  }) async {
    try {
      _logger.i('Uploading bytes to: $path');
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: mimeType ?? 'application/octet-stream'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      _logger.i('Bytes uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('Error uploading bytes: $e');
      rethrow;
    }
  }

  /// Download file from storage
  Future<File> downloadFile({
    required String path,
    required String savePath,
  }) async {
    try {
      _logger.i('Downloading file from: $path to: $savePath');
      final ref = _storage.ref().child(path);
      final file = File(savePath);
      await ref.writeToFile(file);
      _logger.i('File downloaded successfully');
      return file;
    } catch (e) {
      _logger.e('Error downloading file: $e');
      rethrow;
    }
  }

  /// Get download URL
  Future<String> getDownloadUrl(String path) async {
    try {
      _logger.i('Getting download URL for: $path');
      final url = await _storage.ref().child(path).getDownloadURL();
      return url;
    } catch (e) {
      _logger.e('Error getting download URL: $e');
      rethrow;
    }
  }

  /// Delete file from storage
  Future<void> deleteFile(String path) async {
    try {
      _logger.i('Deleting file: $path');
      await _storage.ref().child(path).delete();
      _logger.i('File deleted successfully');
    } catch (e) {
      _logger.e('Error deleting file: $e');
      rethrow;
    }
  }

  /// List files in a directory
  Future<ListResult> listFiles(String path) async {
    try {
      _logger.i('Listing files in: $path');
      final result = await _storage.ref().child(path).listAll();
      return result;
    } catch (e) {
      _logger.e('Error listing files: $e');
      rethrow;
    }
  }

  /// Get metadata
  Future<FullMetadata> getMetadata(String path) async {
    try {
      _logger.i('Getting metadata for: $path');
      final metadata = await _storage.ref().child(path).getMetadata();
      return metadata;
    } catch (e) {
      _logger.e('Error getting metadata: $e');
      rethrow;
    }
  }
}
