import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.userService});

  final UserService? userService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    User? user;
    try {
      // Enhancement 1: restore the saved profile before selecting the first screen.
      user = await (widget.userService ?? UserService()).getSavedUser();
    } catch (_) {
      user = null;
    }

    if (!mounted) return;
    final destination = user == null
        ? const SignInScreen()
        : HomeScreen(user: user);
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 124,
              height: 124,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Image.asset(
                'assets/images/bulldogs exchange logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.storefront, size: 64, color: colors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bulldogs Exchange',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            const SizedBox.square(
              dimension: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
