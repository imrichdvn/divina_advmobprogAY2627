import 'package:flutter/material.dart';

import '../models/chat_user.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.currentUser, this.chatService});

  final User currentUser;
  final ChatService? chatService;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _searchController = TextEditingController();
  late final ChatService _chatService;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _chatService = widget.chatService ?? ChatService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser.loginType != LoginType.firebase) {
      return const _FirebaseChatNotice();
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search by name or email',
            leading: const Icon(Icons.search),
            trailing: [
              if (_query.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close),
                ),
            ],
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChatUser>>(
            stream: _chatService.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _MessageState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load users',
                  message: snapshot.error.toString(),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final query = _query.toLowerCase();
              final users = snapshot.data!.where((user) {
                return query.isEmpty ||
                    user.displayName.toLowerCase().contains(query) ||
                    user.email.toLowerCase().contains(query);
              }).toList();
              if (users.isEmpty) {
                return _MessageState(
                  icon: query.isEmpty
                      ? Icons.people_outline
                      : Icons.search_off_rounded,
                  title: query.isEmpty ? 'No other users yet' : 'No matches',
                  message: query.isEmpty
                      ? 'New Firebase accounts will appear here.'
                      : 'Try a different name or email address.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      leading: Hero(
                        tag: 'chat-avatar-${user.uid}',
                        child: CircleAvatar(child: Text(user.initials)),
                      ),
                      title: Text(
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatDetailScreen(
                            receiver: user,
                            chatService: _chatService,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FirebaseChatNotice extends StatelessWidget {
  const _FirebaseChatNotice();

  @override
  Widget build(BuildContext context) {
    return const _MessageState(
      icon: Icons.local_fire_department_outlined,
      title: 'Firebase sign-in required',
      message: 'Sign out, then choose Firebase to use real-time chat.',
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
