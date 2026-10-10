import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.userService});

  final UserService? userService;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _signingIn = false;
  LoginType _loginType = LoginType.firebase;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _signingIn = true;
      _error = null;
    });

    try {
      // Enhancement 2: authenticate with UserService and persist the returned profile.
      final userService = widget.userService ?? UserService();
      final userData = _loginType == LoginType.firebase
          ? await userService.signInWithFirebase(
              _usernameController.text.trim(),
              _passwordController.text,
            )
          : await userService.loginUser(
              _usernameController.text.trim(),
              _passwordController.text,
            );
      if (!mounted) return;
      await Navigator.pushNamedAndRemoveUntil<void>(
        context,
        '/welcome',
        (_) => false,
        arguments: userData,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Image.asset(
                          'assets/images/bulldogs exchange logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              Icon(Icons.storefront, color: colors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your Bulldogs Exchange account.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    SegmentedButton<LoginType>(
                      segments: const [
                        ButtonSegment(
                          value: LoginType.dummyJson,
                          icon: Icon(Icons.cloud_outlined),
                          label: Text('DummyJSON'),
                        ),
                        ButtonSegment(
                          value: LoginType.firebase,
                          icon: Icon(Icons.local_fire_department_outlined),
                          label: Text('Firebase'),
                        ),
                      ],
                      selected: {_loginType},
                      onSelectionChanged: _signingIn
                          ? null
                          : (selection) => setState(() {
                              _loginType = selection.single;
                              _error = null;
                            }),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loginType == LoginType.firebase
                          ? 'Sign in with your Firebase Authentication account.'
                          : 'Demo accounts are stored in this browser only.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      autofillHints: _loginType == LoginType.firebase
                          ? const [AutofillHints.email]
                          : const [AutofillHints.username],
                      keyboardType: _loginType == LoginType.firebase
                          ? TextInputType.emailAddress
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: _loginType == LoginType.firebase
                            ? 'Email address'
                            : 'Username',
                        prefixIcon: Icon(
                          _loginType == LoginType.firebase
                              ? Icons.mail_outline
                              : Icons.person_outline,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final credential = value?.trim() ?? '';
                        if (credential.isEmpty) {
                          return _loginType == LoginType.firebase
                              ? 'Enter your email address.'
                              : 'Enter your username.';
                        }
                        if (_loginType == LoginType.firebase &&
                            (!credential.contains('@') ||
                                !credential.contains('.'))) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your password.'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: TextStyle(color: colors.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _signingIn ? null : _signIn,
                      icon: _signingIn
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(_signingIn ? 'Signing in...' : 'Sign in'),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _signingIn
                          ? null
                          : () => Navigator.pushNamed(context, '/signup'),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('New here? Create an account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
