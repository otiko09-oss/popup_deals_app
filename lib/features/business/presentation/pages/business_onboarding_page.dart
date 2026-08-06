import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/constants/marketplace_categories.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BusinessOnboardingPage extends ConsumerStatefulWidget {
  const BusinessOnboardingPage({super.key});

  @override
  ConsumerState<BusinessOnboardingPage> createState() =>
      _BusinessOnboardingPageState();
}

class _BusinessOnboardingPageState
    extends ConsumerState<BusinessOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  String _category = MarketplaceCategories.all.first.id;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final firebaseUser = ref.read(authStateProvider).asData?.value;
    if (firebaseUser == null) return;

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(firebaseUser.uid)
          .set({
        'id': firebaseUser.uid,
        'name': _nameController.text.trim(),
        'email': firebaseUser.email ?? '',
        'phoneNumber': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'category': _category,
        'latitude': 0.0,
        'longitude': 0.0,
        'isVerified': false,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'profileComplete': true,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .update({'businessProfileComplete': true});

      if (mounted) {
        context.go(AppRoutes.subscription);
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Business Profile')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            children: [
              Text(
                'Set up your business profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Customers will see this information on your deals.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: MarketplaceCategories.all
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.emoji} ${c.labelEn}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) => v == null || v.trim().length < 10
                    ? 'Min 10 characters'
                    : null,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue to Subscription'),
              ),
            ],
          ),
        ),
      );
}
