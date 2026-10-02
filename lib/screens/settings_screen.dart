import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/user_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            value: theme.isDark,
            onChanged: (_) => theme.toggleTheme(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            subtitle: const Text(
              'Clear the current session and return to login',
            ),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                await UserService().signOut();
                if (!context.mounted) return;
                await navigator.pushNamedAndRemoveUntil<void>(
                  '/signin',
                  (_) => false,
                );
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Could not logout: $error')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
