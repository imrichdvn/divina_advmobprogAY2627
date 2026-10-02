import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.onSignOut,
    this.userService,
  });

  final User user;
  final VoidCallback onSignOut;
  final UserService? userService;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            children: [
              _UserAvatar(user: user, radius: 42),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isEmpty ? user.username : user.fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('@${user.username}'),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfileDetail(
                icon: Icons.badge_outlined,
                label: 'Customer #${user.id}',
              ),
              if (user.gender.isNotEmpty)
                _ProfileDetail(icon: Icons.person_outline, label: user.gender),
              if (user.age > 0)
                _ProfileDetail(
                  icon: Icons.cake_outlined,
                  label: 'Age ${user.age}',
                ),
              if (user.contactNo.isNotEmpty)
                _ProfileDetail(
                  icon: Icons.phone_outlined,
                  label: user.contactNo,
                ),
              _ProfileDetail(
                icon: user.loginType == LoginType.firebase
                    ? Icons.local_fire_department_outlined
                    : Icons.cloud_outlined,
                label: user.loginType.label,
              ),
            ],
          ),
          const SizedBox(height: 22),
          _AccountActions(
            initialUser: user,
            userService: userService ?? UserService(),
            onSignOut: onSignOut,
          ),
          const SizedBox(height: 28),
          Text(
            'Exchange updates',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          // Enhancement 3: render the authenticated user and profile interactions.
          _ProfilePostCard(
            user: user,
            message:
                'Welcome to Bulldogs Exchange. Your next great find starts here.',
            initialLikes: 12,
            initialComments: 3,
          ),
          const SizedBox(height: 10),
          _ProfilePostCard(
            user: user,
            message: 'Browse the catalog and discover something worth sharing.',
            initialLikes: 8,
            initialComments: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Your password is never saved on this device.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountActions extends StatefulWidget {
  const _AccountActions({
    required this.initialUser,
    required this.userService,
    required this.onSignOut,
  });

  final User initialUser;
  final UserService userService;
  final VoidCallback onSignOut;

  @override
  State<_AccountActions> createState() => _AccountActionsState();
}

class _AccountActionsState extends State<_AccountActions> {
  late User _user = widget.initialUser;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final user = User.fromJson(await widget.userService.getUserData());
      if (mounted && user.id != 0) setState(() => _user = user);
    } catch (_) {
      // The route-provided profile remains a valid display fallback.
    }
  }

  Future<void> _updateUsername() async {
    final controller = TextEditingController(text: _user.username);
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update username'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (username == null || username.isEmpty) return;
    await _runAction(
      () => widget.userService.updateUsername(username: username),
      'Username updated.',
      refresh: true,
    );
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final passwords = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password (6+ characters)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (current.text.isNotEmpty && next.text.length >= 6) {
                Navigator.pop(context, (current.text, next.text));
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
    current.dispose();
    next.dispose();
    if (passwords == null) return;
    await _runAction(
      () => widget.userService.resetPasswordFromCurrentPassword(
        currentPassword: passwords.$1,
        newPassword: passwords.$2,
        email: _user.email,
      ),
      'Password changed.',
    );
  }

  Future<void> _deleteAccount() async {
    final password = TextEditingController();
    final confirmedPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Firebase account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This permanently deletes the authenticated account.'),
            const SizedBox(height: 16),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, password.text),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    password.dispose();
    if (confirmedPassword == null || confirmedPassword.isEmpty) return;
    await _runAction(
      () => widget.userService.deleteAccount(
        email: _user.email,
        password: confirmedPassword,
      ),
      'Account deleted.',
      afterSuccess: widget.onSignOut,
    );
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage, {
    bool refresh = false,
    VoidCallback? afterSuccess,
  }) async {
    setState(() => _working = true);
    try {
      await action();
      if (!mounted) return;
      if (refresh) await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      afterSuccess?.call();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseAccount = _user.loginType == LoginType.firebase;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Account management',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (firebaseAccount) ...[
              OutlinedButton.icon(
                onPressed: _working ? null : _updateUsername,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Update username'),
              ),
              OutlinedButton.icon(
                onPressed: _working ? null : _changePassword,
                icon: const Icon(Icons.password_outlined),
                label: const Text('Change password'),
              ),
              OutlinedButton.icon(
                onPressed: _working ? null : _deleteAccount,
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Delete account'),
              ),
            ] else
              const Text(
                'Username and password changes are secured by Firebase accounts.',
              ),
            const SizedBox(height: 6),
            FilledButton.tonalIcon(
              onPressed: _working ? null : widget.onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user, required this.radius});

  final User user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = Text(
      _initials(user),
      style: TextStyle(
        color: colors.onPrimaryContainer,
        fontWeight: FontWeight.w700,
        fontSize: radius * 0.55,
      ),
    );
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      child: user.image.isEmpty
          ? fallback
          : ClipOval(
              child: Image.network(
                user.image,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
            ),
    );
  }

  String _initials(User user) {
    final first = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final last = user.lastName.isNotEmpty ? user.lastName[0] : '';
    final initials = '$first$last'.toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 17),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ProfilePostCard extends StatefulWidget {
  const _ProfilePostCard({
    required this.user,
    required this.message,
    required this.initialLikes,
    required this.initialComments,
  });

  final User user;
  final String message;
  final int initialLikes;
  final int initialComments;

  @override
  State<_ProfilePostCard> createState() => _ProfilePostCardState();
}

class _ProfilePostCardState extends State<_ProfilePostCard> {
  bool _liked = false;
  late int _commentCount = widget.initialComments;

  Future<void> _addComment() async {
    final comment = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _CommentComposer(),
    );
    if (comment != null && comment.isNotEmpty && mounted) {
      setState(() => _commentCount++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _UserAvatar(user: widget.user, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.user.fullName.isEmpty
                        ? widget.user.username
                        : widget.user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text('Today', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 14),
            Text(widget.message),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Row(
              children: [
                IconButton(
                  tooltip: _liked ? 'Unlike update' : 'Like update',
                  onPressed: () => setState(() => _liked = !_liked),
                  color: _liked ? colors.error : null,
                  icon: Icon(_liked ? Icons.favorite : Icons.favorite_border),
                ),
                Text('${widget.initialLikes + (_liked ? 1 : 0)}'),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Comment on update',
                  onPressed: _addComment,
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                Text('$_commentCount'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentComposer extends StatefulWidget {
  const _CommentComposer();

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add a comment', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 240,
            textInputAction: TextInputAction.send,
            decoration: const InputDecoration(
              hintText: 'Write a comment',
              border: OutlineInputBorder(),
            ),
            onSubmitted: _submit,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _submit(_controller.text),
              icon: const Icon(Icons.send),
              label: const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(String value) {
    final comment = value.trim();
    if (comment.isNotEmpty) Navigator.of(context).pop(comment);
  }
}
