import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:popup_deals_app/core/providers/locale_provider.dart';
import 'package:popup_deals_app/core/providers/notification_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(notificationSettingsProvider).maybeWhen(
            data: (value) => value,
            orElse: () => null,
          );
      if (settings != null) {
        setState(() {
          _notificationsEnabled =
              settings.authorizationStatus == AuthorizationStatus.authorized;
        });
      }
    });
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final service = ref.read(notificationServiceProvider);
    if (enabled) {
      final settings = await service.requestPermission();
      setState(() {
        _notificationsEnabled =
            settings.authorizationStatus == AuthorizationStatus.authorized;
      });
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await service.getToken();
        if (token != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications enabled')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications permission denied'),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please disable notifications from device settings.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language'),
              subtitle: Text(locale.languageCode.toUpperCase()),
              trailing: PopupMenuButton<String>(
                onSelected: (code) async {
                  await ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(code));
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'en', child: Text('English')),
                  PopupMenuItem(value: 'ka', child: Text('ქართული')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.attach_money_outlined),
              title: const Text('Currency'),
              subtitle: Text(currency),
              trailing: PopupMenuButton<String>(
                onSelected: (code) async {
                  await ref.read(currencyProvider.notifier).setCurrency(code);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'USD', child: Text('USD')),
                  PopupMenuItem(value: 'EUR', child: Text('EUR')),
                  PopupMenuItem(value: 'GBP', child: Text('GBP')),
                  PopupMenuItem(value: 'GEL', child: Text('GEL')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile.adaptive(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              subtitle: const Text('Enable or disable app notifications'),
            ),
          ),
        ],
      ),
    );
  }
}
