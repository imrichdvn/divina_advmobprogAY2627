import 'package:divina_advmobprog/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sign-up form validates required fields and email', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pump();

    expect(find.text('Enter your first name.'), findsOneWidget);
    expect(find.text('Enter your last name.'), findsOneWidget);
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter 1-120.'), findsOneWidget);
    expect(find.text('Enter 7-15 digits.'), findsOneWidget);
    expect(find.text('Choose a username.'), findsOneWidget);
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('email validator rejects malformed addresses with at signs', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

    await tester.enterText(find.byType(TextFormField).at(2), 'name@.');
    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('email validator accepts a valid address with a subdomain', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

    await tester.enterText(
      find.byType(TextFormField).at(2),
      'new.customer+shop@example.co.uk',
    );
    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsNothing);
  });
}
