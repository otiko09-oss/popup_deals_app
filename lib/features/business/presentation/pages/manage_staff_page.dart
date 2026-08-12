import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/business_staff_service.dart';

final businessStaffServiceProvider =
    Provider<BusinessStaffService>((ref) => BusinessStaffService());

/// Lets a business owner add/remove staff members who can then scan and
/// redeem QR codes on the business's behalf. Staff must already have a
/// Popup Deals account — the owner adds them by their account UID (shown
/// on the staff member's own Profile page).
class ManageStaffPage extends ConsumerStatefulWidget {
  const ManageStaffPage({super.key});

  @override
  ConsumerState<ManageStaffPage> createState() => _ManageStaffPageState();
}

class _ManageStaffPageState extends ConsumerState<ManageStaffPage> {
  final _uidController = TextEditingController();
  final _nameController = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _uidController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addStaff(String businessId) async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) return;

    setState(() => _adding = true);
    try {
      await ref.read(businessStaffServiceProvider).addStaff(
            businessId: businessId,
            staffUid: uid,
            displayName: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
          );
      _uidController.clear();
      _nameController.clear();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not add staff: $e')));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessId = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final staffStream =
        ref.watch(businessStaffServiceProvider).staffStream(businessId);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Staff')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add a staff member',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'They need a Popup Deals account already. Ask them for '
                      'their account UID (visible on their Profile page).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _uidController,
                      decoration: const InputDecoration(
                        labelText: 'Staff account UID',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display name (optional)',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _adding ? null : () => _addStaff(businessId),
                      child: _adding
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add Staff'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder(
              stream: staffStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final staff = snapshot.data!;
                if (staff.isEmpty) {
                  return const Center(child: Text('No staff added yet'));
                }
                return ListView.builder(
                  itemCount: staff.length,
                  itemBuilder: (context, index) {
                    final member = staff[index];
                    final active = member['isActive'] == true;
                    final uid = member['id'] as String;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: active
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.person,
                          color: active ? Colors.green : Colors.grey,
                        ),
                      ),
                      title: Text(member['displayName'] as String? ?? uid),
                      subtitle: Text(active ? 'Active' : 'Deactivated'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) {
                          final service = ref.read(businessStaffServiceProvider);
                          switch (action) {
                            case 'toggle':
                              active
                                  ? service.deactivateStaff(uid)
                                  : service.reactivateStaff(uid);
                            case 'remove':
                              service.removeStaff(uid);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(active ? 'Deactivate' : 'Reactivate'),
                          ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
