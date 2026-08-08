import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

final platformStatsProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(adminServiceProvider).getPlatformStats();
});

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(platformStatsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Users'),
              Tab(text: 'Businesses'),
              Tab(text: 'Deals'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (stats) => _OverviewTab(stats: stats),
            ),
            const _UsersTab(),
            const _BusinessesTab(),
            const _DealsModerationTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.stats});
  final Map<String, int> stats;

  @override
  Widget build(BuildContext context) => GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _StatTile(
            label: 'Users',
            value: '${stats['users'] ?? 0}',
            icon: Icons.people,
            color: Colors.blue,
          ),
          _StatTile(
            label: 'Businesses',
            value: '${stats['businesses'] ?? 0}',
            icon: Icons.store,
            color: Colors.green,
          ),
          _StatTile(
            label: 'Deals',
            value: '${stats['deals'] ?? 0}',
            icon: Icons.local_offer,
            color: Colors.orange,
          ),
          _StatTile(
            label: 'Redemptions',
            value: '${stats['redemptions'] ?? 0}',
            icon: Icons.qr_code,
            color: Colors.purple,
          ),
        ],
      );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label),
          ],
        ),
      );
}

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersStream = ref.watch(adminServiceProvider).usersStream();

    return StreamBuilder(
      stream: usersStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!;
        if (users.isEmpty) {
          return const Center(child: Text('No users yet'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final blocked = user['isBlocked'] == true;

            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  (user['email'] as String? ?? '?')
                      .substring(0, 1)
                      .toUpperCase(),
                ),
              ),
              title: Text(user['displayName'] as String? ??
                  user['email'] as String? ??
                  ''),
              subtitle: Text('${user['userType']} · ${user['email']}'),
              trailing: IconButton(
                icon: Icon(blocked ? Icons.lock_open : Icons.block),
                onPressed: () async {
                  await ref.read(adminServiceProvider).setUserBlocked(
                        user['id'] as String,
                        blocked: !blocked,
                      );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _BusinessesTab extends ConsumerWidget {
  const _BusinessesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessesStream = ref.watch(adminServiceProvider).businessesStream();

    return StreamBuilder(
      stream: businessesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final businesses = snapshot.data!;
        if (businesses.isEmpty) {
          return const Center(child: Text('No businesses yet'));
        }

        return ListView.builder(
          itemCount: businesses.length,
          itemBuilder: (context, index) {
            final business = businesses[index];
            final verified = business['isVerified'] == true;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    verified ? Colors.green.withValues(alpha: 0.15) : null,
                child: Icon(
                  Icons.store,
                  color: verified ? Colors.green : null,
                ),
              ),
              title: Text(business['name'] as String? ?? 'Unnamed business'),
              subtitle: Text(
                verified ? 'Verified' : 'Not verified',
                style: TextStyle(
                  color: verified ? Colors.green : Colors.orange,
                ),
              ),
              trailing: Switch(
                value: verified,
                onChanged: (value) async {
                  await ref.read(adminServiceProvider).setBusinessVerified(
                        business['id'] as String,
                        verified: value,
                      );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _DealsModerationTab extends ConsumerWidget {
  const _DealsModerationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsStream = ref.watch(adminServiceProvider).pendingDealsStream();

    return StreamBuilder(
      stream: dealsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final deals = snapshot.data!;
        if (deals.isEmpty) {
          return const Center(child: Text('No deals pending moderation'));
        }

        return ListView.builder(
          itemCount: deals.length,
          itemBuilder: (context, index) {
            final deal = deals[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                title: Text(deal['title'] as String? ?? 'Untitled'),
                subtitle: Text(deal['restaurant'] as String? ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () =>
                          ref.read(adminServiceProvider).moderateDeal(
                                dealId: deal['id'] as String,
                                status: 'approved',
                              ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () =>
                          ref.read(adminServiceProvider).moderateDeal(
                                dealId: deal['id'] as String,
                                status: 'rejected',
                              ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
