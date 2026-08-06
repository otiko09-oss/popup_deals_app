import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:popup_deals_app/features/profile/presentation/pages/edit_profile_page.dart';

void main() {
  testWidgets('edit profile page renders editable profile fields',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: EditProfilePage()),
      ),
    );

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Save Changes'), findsOneWidget);
  });
}
