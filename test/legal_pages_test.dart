import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:popup_deals_app/features/profile/presentation/pages/help_support_page.dart';
import 'package:popup_deals_app/features/profile/presentation/pages/terms_of_service_page.dart';

void main() {
  testWidgets('support and terms pages show expected content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpSupportPage()));

    expect(find.textContaining('Support'), findsWidgets);
    expect(find.textContaining('support@popupdeals.app'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: TermsOfServicePage()));

    expect(find.textContaining('Terms'), findsWidgets);
  });
}
