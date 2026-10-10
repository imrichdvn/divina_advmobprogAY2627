import 'package:divina_advmobprog/models/user.dart';
import 'package:divina_advmobprog/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Firebase is selected by default for sign-in', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));

    final selector = tester.widget<SegmentedButton<LoginType>>(
      find.byType(SegmentedButton<LoginType>),
    );
    expect(selector.selected, {LoginType.firebase});
    expect(
      find.text('Sign in with your Firebase Authentication account.'),
      findsOneWidget,
    );
  });
}
