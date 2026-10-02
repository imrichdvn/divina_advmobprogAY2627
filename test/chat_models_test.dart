import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:divina_advmobprog/models/chat_user.dart';
import 'package:divina_advmobprog/models/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatUser', () {
    test('uses the full name and creates two-letter initials', () {
      final user = ChatUser.fromMap('uid-2', {
        'email': 'grace@example.com',
        'firstName': 'Grace',
        'lastName': 'Hopper',
        'username': 'grace',
      });

      expect(user.uid, 'uid-2');
      expect(user.displayName, 'Grace Hopper');
      expect(user.initials, 'GH');
    });

    test('falls back to username when a name is unavailable', () {
      const user = ChatUser(
        uid: 'uid-3',
        email: 'alan@example.com',
        firstName: '',
        lastName: '',
        username: 'alan',
      );

      expect(user.displayName, 'alan');
      expect(user.initials, 'A');
    });
  });

  test('MessageModel round-trips Firestore message fields', () {
    final timestamp = Timestamp.fromMillisecondsSinceEpoch(123456);
    final message = MessageModel(
      id: 'message-1',
      senderId: 'sender',
      senderEmail: 'sender@example.com',
      receiverId: 'receiver',
      message: 'Hello',
      timestamp: timestamp,
      status: MessageStatus.seen,
      clientMessageId: 'client-1',
      seenAt: timestamp,
    );

    final restored = MessageModel.fromMap('message-1', message.toMap());

    expect(restored.senderId, 'sender');
    expect(restored.receiverId, 'receiver');
    expect(restored.message, 'Hello');
    expect(restored.status, MessageStatus.seen);
    expect(restored.clientMessageId, 'client-1');
    expect(restored.seenAt, timestamp);
  });
}
