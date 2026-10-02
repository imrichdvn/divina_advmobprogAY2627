import 'package:divina_advmobprog/screens/splash_screen.dart';
import 'package:divina_advmobprog/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('splash restores a saved account to the home route', (
    tester,
  ) async {
    final userService = UserService();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('registeredSession', true);
    await preferences.setInt('id', 17);
    await preferences.setString('username', 'returning-user');

    await tester.pumpWidget(_TestApp(userService: userService));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Home for user 17'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash sends a signed-out user to sign-in', (tester) async {
    final userService = UserService();

    await tester.pumpWidget(_TestApp(userService: userService));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('post-auth splash welcomes the user then opens Home', (
    tester,
  ) async {
    const userData = {'id': 25, 'username': 'new-customer', 'firstName': 'New'};

    await tester.pumpWidget(
      _TestApp(userService: UserService(), authenticatedUser: userData),
    );
    await tester.pump();

    expect(find.text('Welcome, New'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Home for user 25'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.userService, this.authenticatedUser});

  final UserService userService;
  final Map<String, dynamic>? authenticatedUser;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(
        userService: userService,
        authenticatedUser: authenticatedUser,
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final user = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(body: Text('Home for user ${user['id']}')),
          );
        }
        if (settings.name == '/signin') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Sign in')),
          );
        }
        return null;
      },
    );
  }
}
