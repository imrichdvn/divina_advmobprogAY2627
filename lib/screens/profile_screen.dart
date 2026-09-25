import 'package:flutter/material.dart';

import '../models/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user, required this.onSignOut});

  final User user;
  final VoidCallback onSignOut;

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
            ],
          ),
          const SizedBox(height: 22),
          FilledButton.tonalIcon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
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
