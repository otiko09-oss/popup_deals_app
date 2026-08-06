import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/deal_creation_form.dart';
import '../providers/business_provider.dart';
import '../widgets/category_and_tags.dart';
import '../widgets/custom_form_field.dart';
import '../widgets/date_time_picker_field.dart';
import '../widgets/deal_image_picker.dart';

/// Screen for businesses to create new deals
class AddDealScreen extends ConsumerStatefulWidget {
  const AddDealScreen({super.key});

  @override
  ConsumerState<AddDealScreen> createState() => _AddDealScreenState();
}

class _AddDealScreenState extends ConsumerState<AddDealScreen> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _oldPriceController;
  late TextEditingController _newPriceController;

  File? _selectedImage;
  DateTime? _startTime;
  DateTime? _endTime;
  String? _selectedCategory;
  List<String> _selectedTags = [];
  double? _latitude;
  double? _longitude;

  // Validation error states
  final Map<String, String?> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _oldPriceController = TextEditingController();
    _newPriceController = TextEditingController();

    // Initialize with current location
    _initializeLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _oldPriceController.dispose();
    _newPriceController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  /// Build deal creation form
  DealCreationForm _buildForm() => DealCreationForm(
        title: _titleController.text,
        description: _descriptionController.text,
        oldPrice: double.tryParse(_oldPriceController.text) ?? 0,
        newPrice: double.tryParse(_newPriceController.text) ?? 0,
        imageFile: _selectedImage,
        startTime: _startTime ?? DateTime.now().add(const Duration(hours: 1)),
        endTime: _endTime ?? DateTime.now().add(const Duration(hours: 3)),
        latitude: _latitude ?? 0,
        longitude: _longitude ?? 0,
        category: _selectedCategory ?? '',
        tags: _selectedTags,
      );

  /// Validate all fields
  bool _validateForm() {
    setState(_fieldErrors.clear);

    final form = _buildForm();
    final error = form.validate();

    if (error != null) {
      setState(() {
        _fieldErrors['form'] = error;
      });
      return false;
    }

    return true;
  }

  /// Handle deal creation
  Future<void> _handleCreateDeal() async {
    if (!_validateForm()) {
      return;
    }

    final appUser = ref.read(authProvider).asData?.value;
    if (appUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to create a deal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final businessId = appUser.uid;
    final restaurantName = appUser.displayName?.isNotEmpty == true
        ? appUser.displayName!
        : appUser.email;

    final form = _buildForm();

    // Create deal
    await ref.read(dealCreationProvider.notifier).createDeal(
          form: form,
          businessId: businessId,
          restaurantName: restaurantName,
        );

    // Listen for completion
    ref.listen(dealCreationProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form after successful creation
        unawaited(Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _clearForm();
          }
        }));
      }
    });
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _oldPriceController.clear();
    _newPriceController.clear();
    setState(() {
      _selectedImage = null;
      _startTime = null;
      _endTime = null;
      _selectedCategory = null;
      _selectedTags = [];
      _fieldErrors.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(dealCreationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Deal'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error message banner
                if (_fieldErrors['form'] != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _fieldErrors['form']!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_fieldErrors['form'] != null) const SizedBox(height: 20),

                // Deal Image Picker
                DealImagePicker(
                  onImageSelected: (file) {
                    setState(() {
                      _selectedImage = file;
                    });
                  },
                  initialImage: _selectedImage,
                ),
                const SizedBox(height: 24),

                // Title
                CustomFormField(
                  label: 'Deal Title',
                  hint: 'e.g., 50% Off Margarita Pizza',
                  controller: _titleController,
                  errorText: _fieldErrors['title'],
                ),
                const SizedBox(height: 20),

                // Description
                CustomFormField(
                  label: 'Description',
                  hint: 'Describe your amazing deal...',
                  controller: _descriptionController,
                  maxLines: 4,
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                  errorText: _fieldErrors['description'],
                ),
                const SizedBox(height: 20),

                // Prices
                Row(
                  children: [
                    Expanded(
                      child: PriceField(
                        label: 'Original Price',
                        controller: _oldPriceController,
                        errorText: _fieldErrors['oldPrice'],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PriceField(
                        label: 'Discounted Price',
                        controller: _newPriceController,
                        errorText: _fieldErrors['newPrice'],
                      ),
                    ),
                  ],
                ),

                // Show discount percentage if both prices are filled
                if (_oldPriceController.text.isNotEmpty &&
                    _newPriceController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_offer, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Discount: ${_buildForm().discountPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Deal Duration
                Text(
                  'Deal Duration',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                // Start Time
                DateTimePickerField(
                  label: 'Start Time',
                  selectedDateTime: _startTime,
                  onDateTimeSelected: (dateTime) {
                    setState(() {
                      _startTime = dateTime;
                    });
                  },
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  errorText: _fieldErrors['startTime'],
                ),
                const SizedBox(height: 16),

                // End Time
                DateTimePickerField(
                  label: 'End Time',
                  selectedDateTime: _endTime,
                  onDateTimeSelected: (dateTime) {
                    setState(() {
                      _endTime = dateTime;
                    });
                  },
                  firstDate: _startTime ?? DateTime.now(),
                  lastDate: (_startTime ?? DateTime.now())
                      .add(const Duration(days: 7)),
                  errorText: _fieldErrors['endTime'],
                ),
                const SizedBox(height: 24),

                // Category
                CategorySelector(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  errorText: _fieldErrors['category'],
                ),
                const SizedBox(height: 20),

                // Tags
                TagsInput(
                  initialTags: _selectedTags,
                  onTagsChanged: (tags) {
                    setState(() {
                      _selectedTags = tags;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Location Info (read-only display)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deal Location',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _latitude != null && _longitude != null
                                  ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                                  : 'Getting location...',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Create Deal Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        creationState.isLoading ? null : _handleCreateDeal,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                    child: creationState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Create Deal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Clear Form Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _clearForm,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Clear Form'),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
