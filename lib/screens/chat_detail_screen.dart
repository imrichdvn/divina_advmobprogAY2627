import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/chat_user.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.receiver,
    required this.chatService,
  });

  final ChatUser receiver;
  final ChatService chatService;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  MessageModel? _pendingMessage;
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    final clientMessageId = '${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _sending = true;
      _pendingMessage = MessageModel(
        id: clientMessageId,
        senderId: widget.chatService.currentUserId,
        senderEmail: widget.chatService.currentUserEmail,
        receiverId: widget.receiver.uid,
        message: text,
        timestamp: Timestamp.now(),
        status: MessageStatus.sending,
        clientMessageId: clientMessageId,
      );
    });
    _messageController.clear();
    try {
      await widget.chatService.sendMessage(
        receiver: widget.receiver,
        message: text,
        clientMessageId: clientMessageId,
      );
      if (mounted) setState(() => _pendingMessage = null);
    } catch (error) {
      if (!mounted) return;
      _messageController.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Message was not sent: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _pendingMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Hero(
              tag: 'chat-avatar-${widget.receiver.uid}',
              child: CircleAvatar(
                radius: 18,
                child: Text(widget.receiver.initials),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiver.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    widget.receiver.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: widget.chatService.getMessages(widget.receiver.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Could not load messages.'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = [...snapshot.data!];
                  final pending = _pendingMessage;
                  if (pending != null &&
                      !messages.any(
                        (message) =>
                            message.clientMessageId == pending.clientMessageId,
                      )) {
                    messages.insert(0, pending);
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.chatService.markMessagesSeen(
                      widget.receiver.uid,
                      snapshot.data!,
                    );
                  });
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.waving_hand_outlined,
                              size: 48,
                              color: colors.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Start the conversation',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Say hello to ${widget.receiver.displayName}.',
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _AnimatedMessageBubble(
                        key: ValueKey(message.id),
                        message: message,
                        sentByMe:
                            message.senderId ==
                            widget.chatService.currentUserId,
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Write a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: _sending ? null : _sendMessage,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _sending
                          ? const SizedBox.square(
                              key: ValueKey('sending'),
                              dimension: 19,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              key: ValueKey('send'),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedMessageBubble extends StatelessWidget {
  const _AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.sentByMe,
  });

  final MessageModel message;
  final bool sentByMe;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final time = TimeOfDay.fromDateTime(
      message.timestamp.toDate(),
    ).format(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset((sentByMe ? 1 : -1) * 18 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Align(
        alignment: sentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
          decoration: BoxDecoration(
            color: sentByMe ? colors.primaryContainer : colors.surfaceContainer,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(sentByMe ? 18 : 4),
              bottomRight: Radius.circular(sentByMe ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.message),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: Theme.of(context).textTheme.labelSmall),
                  if (sentByMe) ...[
                    const SizedBox(width: 4),
                    if (message.status == MessageStatus.sending)
                      Text(
                        'sending…',
                        style: Theme.of(context).textTheme.labelSmall,
                      )
                    else
                      Icon(
                        message.status == MessageStatus.seen
                            ? Icons.done_all
                            : Icons.done,
                        size: 16,
                        color: message.status == MessageStatus.seen
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
