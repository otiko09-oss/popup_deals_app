import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri.parse(
        'mailto:support@popupdeals.app?subject=Popup%20Deals%20Support');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to open your mail app right now.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need help?',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Our support team is available to assist with account issues, deal problems, and redemption questions.',
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _openEmail(context),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Contact support'),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Support contact',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text('Email: support@popupdeals.app'),
                      const SizedBox(height: 4),
                      const Text(
                          'Response time: usually within 1 business day.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
