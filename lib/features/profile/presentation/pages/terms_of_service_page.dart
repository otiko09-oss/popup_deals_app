import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'By using Popup Deals, you agree to use the service responsibly and provide accurate account information. You are responsible for keeping your login credentials secure.',
              ),
              SizedBox(height: 12),
              Text(
                'Business accounts may publish deals and manage orders within the app. Any misuse, fraudulent activity, or abuse of the platform may result in account suspension.',
              ),
              SizedBox(height: 12),
              Text(
                'These terms may be updated from time to time to reflect new features or legal requirements.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
