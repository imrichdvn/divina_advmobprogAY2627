import 'package:flutter/material.dart';

import '../services/user_service.dart';

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
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    try {
      final userService = widget.userService ?? UserService();
      final loggedIn = await userService.isLoggedIn();
      if (!mounted) return;

      if (loggedIn) {
        // Enhancement 1: restore the profile and route returning users to Home.
        final userData = await userService.getUserData();
        if (!mounted) return;
        await Navigator.pushReplacementNamed<void, void>(
          context,
          '/home',
          arguments: userData,
        );
      } else {
        await Navigator.pushReplacementNamed<void, void>(context, '/signin');
      }
    } catch (_) {
      if (!mounted) return;
      await Navigator.pushReplacementNamed<void, void>(context, '/signin');
    }
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
