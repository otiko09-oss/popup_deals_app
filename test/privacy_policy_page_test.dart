import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:popup_deals_app/features/profile/presentation/pages/privacy_policy_page.dart';

void main() {
  testWidgets('Privacy policy page shows the expected content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyPage()));

    expect(find.textContaining('Privacy Policy'), findsNWidgets(2));
    expect(find.textContaining('We respect your privacy'), findsOneWidget);
  });
}
