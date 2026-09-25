import 'package:divina_advmobprog/models/user.dart';
import 'package:divina_advmobprog/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = User(
    id: 7,
    username: 'sample-user',
    email: 'sample@example.com',
    firstName: 'Sample',
    lastName: 'User',
    gender: 'female',
    image: '',
  );

  testWidgets('profile renders saved user and an initials avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileScreen(user: user, onSignOut: _noop),
        ),
      ),
    );

    expect(find.text('Sample User'), findsNWidgets(3));
    expect(find.text('@sample-user'), findsOneWidget);
    expect(find.text('sample@example.com'), findsOneWidget);
    expect(find.text('Customer #7'), findsOneWidget);
    expect(find.text('SU'), findsNWidgets(3));
    expect(find.byTooltip('Like update'), findsNWidgets(2));
    expect(find.byTooltip('Comment on update'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('like and comment controls update their counts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileScreen(user: user, onSignOut: _noop),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Like update').first);
    await tester.pump();
    expect(find.text('13'), findsOneWidget);

    await tester.tap(find.byTooltip('Comment on update').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Great find!');
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
