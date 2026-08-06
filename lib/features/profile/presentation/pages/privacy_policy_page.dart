import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Privacy Policy')),
        body: const SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'We respect your privacy. This app collects only the information necessary to provide authentication, deal browsing, favorites, and order features.',
                ),
                SizedBox(height: 12),
                Text(
                  'We use Firebase services to store account information, favorites, and orders. You can request account deletion or contact support for more information.',
                ),
              ],
            ),
          ),
        ),
      );
}
