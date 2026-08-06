import 'dart:io';

/// Form model for creating a deal - holds all user input data
class DealCreationForm {
  DealCreationForm({
    required this.title,
    required this.description,
    required this.oldPrice,
    required this.newPrice,
    required this.startTime,
    required this.endTime,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.imageFile,
    this.tags = const [],
  });
  final String title;
  final String description;
  final double oldPrice;
  final double newPrice;
  final File? imageFile;
  final DateTime startTime;
  final DateTime endTime;
  final double latitude;
  final double longitude;
  final String category;
  final List<String> tags;

  /// Validate form data.
  /// [requireImage] should be false when editing a deal that already has
  /// an uploaded image and the user hasn't picked a new one.
  String? validate({bool requireImage = true}) {
    if (title.trim().isEmpty) {
      return 'Title is required';
    }
    if (title.length < 5) {
      return 'Title must be at least 5 characters';
    }
    if (title.length > 100) {
      return 'Title must not exceed 100 characters';
    }

    if (description.trim().isEmpty) {
      return 'Description is required';
    }
    if (description.length < 10) {
      return 'Description must be at least 10 characters';
    }
    if (description.length > 500) {
      return 'Description must not exceed 500 characters';
    }

    if (oldPrice <= 0) {
      return 'Original price must be greater than 0';
    }
    if (newPrice <= 0) {
      return 'Discounted price must be greater than 0';
    }
    if (newPrice >= oldPrice) {
      return 'Discounted price must be less than original price';
    }

    if (requireImage && imageFile == null) {
      return 'Deal image is required';
    }

    final now = DateTime.now();
    if (startTime.isBefore(now)) {
      return 'Start time must be in the future';
    }
    if (endTime.isBefore(startTime)) {
      return 'End time must be after start time';
    }

    const maxDuration = Duration(days: 7);
    if (endTime.difference(startTime) > maxDuration) {
      return 'Deal duration cannot exceed 7 days';
    }

    if (category.isEmpty) {
      return 'Category is required';
    }

    return null; // No errors
  }

  /// Calculate discount percentage
  double get discountPercentage {
    if (oldPrice == 0) return 0;
    return ((oldPrice - newPrice) / oldPrice * 100).roundToDouble();
  }

  /// Check if form is valid
  bool get isValid => validate() == null;

  @override
  String toString() => 'DealCreationForm('
      'title: $title, '
      'oldPrice: $oldPrice, '
      'newPrice: $newPrice, '
      'startTime: $startTime, '
      'endTime: $endTime'
      ')';
}

extension DoubleRounding on double {
  double roundToDouble({int places = 2}) {
    final factor = 10.0 * places;
    return (this * factor).round() / factor;
  }
}
