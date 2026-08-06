import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/deal_creation_form.dart';
import '../providers/business_provider.dart';
import '../widgets/category_and_tags.dart';
import '../widgets/custom_form_field.dart';
import '../widgets/date_time_picker_field.dart';
import '../widgets/deal_image_picker.dart';

/// Screen for businesses to edit an existing deal.
class EditDealScreen extends ConsumerStatefulWidget {
  const EditDealScreen({required this.dealId, super.key});
  final String dealId;

  @override
  ConsumerState<EditDealScreen> createState() => _EditDealScreenState();
}

class _EditDealScreenState extends ConsumerState<EditDealScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _oldPriceController = TextEditingController();
  final TextEditingController _newPriceController = TextEditingController();

  bool _initialized = false;
  File? _selectedImage;
  String? _existingImageUrl;
  DateTime? _startTime;
  DateTime? _endTime;
  String? _selectedCategory;
  List<String> _selectedTags = [];
  double _latitude = 0;
  double _longitude = 0;

  final Map<String, String?> _fieldErrors = {};

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _oldPriceController.dispose();
    _newPriceController.dispose();
    super.dispose();
  }

  void _prefill(Map<String, dynamic> deal) {
    _titleController.text = deal['title'] as String? ?? '';
    _descriptionController.text = deal['description'] as String? ?? '';
    _oldPriceController.text = (deal['originalPrice'] ?? '').toString();
    _newPriceController.text = (deal['discountedPrice'] ?? '').toString();
    _existingImageUrl = deal['imageUrl'] as String?;
    _selectedCategory = deal['category'] as String?;
    _selectedTags = List<String>.from(deal['tags'] as List? ?? []);
    _latitude = (deal['latitude'] as num?)?.toDouble() ?? 0;
    _longitude = (deal['longitude'] as num?)?.toDouble() ?? 0;
    _startTime = deal['startTime'] != null
        ? DateTime.tryParse(deal['startTime'] as String)
        : null;
    _endTime = deal['endTime'] != null
        ? DateTime.tryParse(deal['endTime'] as String)
        : null;
    _initialized = true;
  }

  DealCreationForm _buildForm() => DealCreationForm(
        title: _titleController.text,
        description: _descriptionController.text,
        oldPrice: double.tryParse(_oldPriceController.text) ?? 0,
        newPrice: double.tryParse(_newPriceController.text) ?? 0,
        imageFile: _selectedImage,
        startTime: _startTime ?? DateTime.now().add(const Duration(hours: 1)),
        endTime: _endTime ?? DateTime.now().add(const Duration(hours: 3)),
        latitude: _latitude,
        longitude: _longitude,
        category: _selectedCategory ?? '',
        tags: _selectedTags,
      );

  bool _validateForm() {
    setState(_fieldErrors.clear);
    final form = _buildForm();
    final error = form.validate(requireImage: _existingImageUrl == null);
    if (error != null) {
      setState(() => _fieldErrors['form'] = error);
      return false;
    }
    return true;
  }

  Future<void> _handleUpdate() async {
    if (!_validateForm()) return;

    final appUser = ref.read(authProvider).asData?.value;
    if (appUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to edit a deal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final restaurantName = appUser.displayName?.isNotEmpty == true
        ? appUser.displayName!
        : appUser.email;

    await ref.read(dealCreationProvider.notifier).updateDeal(
          dealId: widget.dealId,
          form: _buildForm(),
          businessId: appUser.uid,
          restaurantName: restaurantName,
          existingImageUrl: _existingImageUrl,
        );

    if (!mounted) return;

    final state = ref.read(dealCreationProvider);
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
      );
    } else if (state.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage!),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dealAsync = ref.watch(dealProvider(widget.dealId));
    final creationState = ref.watch(dealCreationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Deal'), elevation: 0),
      body: dealAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error loading deal: $error')),
        data: (deal) {
          if (deal == null) {
            return const Center(child: Text('Deal not found'));
          }
          if (!_initialized) {
            _prefill(deal);
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            Icon(Icons.error_outline,
                                color: Colors.red.shade600),
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
                    if (_fieldErrors['form'] != null)
                      const SizedBox(height: 20),
                    if (_existingImageUrl != null && _selectedImage == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _existingImageUrl!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 160,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                      ),
                    Text(
                      'Pick a new photo to replace the current one (optional)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    DealImagePicker(
                      onImageSelected: (file) {
                        setState(() => _selectedImage = file);
                      },
                      initialImage: _selectedImage,
                    ),
                    const SizedBox(height: 24),
                    CustomFormField(
                      label: 'Deal Title',
                      hint: 'e.g., 50% Off Margarita Pizza',
                      controller: _titleController,
                      errorText: _fieldErrors['title'],
                    ),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 24),
                    Text(
                      'Deal Duration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DateTimePickerField(
                      label: 'Start Time',
                      selectedDateTime: _startTime,
                      onDateTimeSelected: (dateTime) {
                        setState(() => _startTime = dateTime);
                      },
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                      errorText: _fieldErrors['startTime'],
                    ),
                    const SizedBox(height: 16),
                    DateTimePickerField(
                      label: 'End Time',
                      selectedDateTime: _endTime,
                      onDateTimeSelected: (dateTime) {
                        setState(() => _endTime = dateTime);
                      },
                      firstDate: _startTime ?? DateTime.now(),
                      lastDate: (_startTime ?? DateTime.now())
                          .add(const Duration(days: 7)),
                      errorText: _fieldErrors['endTime'],
                    ),
                    const SizedBox(height: 24),
                    CategorySelector(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() => _selectedCategory = category);
                      },
                      errorText: _fieldErrors['category'],
                    ),
                    const SizedBox(height: 20),
                    TagsInput(
                      initialTags: _selectedTags,
                      onTagsChanged: (tags) {
                        setState(() => _selectedTags = tags);
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            creationState.isLoading ? null : _handleUpdate,
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
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
