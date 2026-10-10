import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_user.dart';
import '../models/message.dart';
import '../models/user.dart' as app;

class ChatService {
  ChatService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserEmail => _auth.currentUser?.email ?? '';

  Stream<List<ChatUser>> getUsersStream() {
    final ownUid = currentUserId;
    return _firestore.collection('Users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => ChatUser.fromMap(doc.id, doc.data()))
          .where((user) => user.uid != ownUid && user.email.isNotEmpty)
          .toList();
      users.sort(
        (first, second) => first.displayName.toLowerCase().compareTo(
          second.displayName.toLowerCase(),
        ),
      );
      return users;
    });
  }

  Future<void> syncCurrentUserProfile(app.User profile) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    await _firestore.collection('Users').doc(uid).set({
      'uid': uid,
      'email': currentUserEmail.isNotEmpty ? currentUserEmail : profile.email,
      'firstName': profile.firstName,
      'lastName': profile.lastName,
      'username': profile.username,
      'image': profile.image,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendMessage({
    required ChatUser receiver,
    required String message,
    required String clientMessageId,
  }) async {
    final senderId = currentUserId;
    if (senderId.isEmpty) throw StateError('Sign in with Firebase first.');
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) return;
    if (receiver.uid.isEmpty || receiver.uid == senderId) {
      throw ArgumentError('Choose another valid chat user.');
    }
    if (normalizedMessage.length > 4000) {
      throw ArgumentError('Messages must be 4000 characters or fewer.');
    }
    if (clientMessageId.trim().isEmpty || clientMessageId.contains('/')) {
      throw ArgumentError.value(clientMessageId, 'clientMessageId');
    }

    final roomId = _chatRoomId(senderId, receiver.uid);
    final room = _firestore.collection('chat_rooms').doc(roomId);
    final participants = [senderId, receiver.uid]..sort();
    await room.set({
      'participants': participants,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final messageRef = room.collection('messages').doc(clientMessageId);
    final messageData = MessageModel(
      id: clientMessageId,
      senderId: senderId,
      senderEmail: currentUserEmail,
      receiverId: receiver.uid,
      message: normalizedMessage,
      timestamp: Timestamp.now(),
      status: MessageStatus.delivered,
      clientMessageId: clientMessageId,
    ).toMap();
    await _firestore.runTransaction((transaction) async {
      final existingMessage = await transaction.get(messageRef);
      if (existingMessage.exists) {
        final existingData = existingMessage.data();
        if (existingData?['senderId'] == senderId &&
            existingData?['receiverId'] == receiver.uid &&
            existingData?['message'] == normalizedMessage &&
            existingData?['clientMessageId'] == clientMessageId) {
          return;
        }
        throw StateError('This message ID is already in use.');
      }
      transaction.set(messageRef, messageData);
    });
  }

  Stream<List<MessageModel>> getMessages(String otherUserId) {
    final ownUid = currentUserId;
    if (ownUid.isEmpty) return const Stream.empty();
    return _firestore
        .collection('chat_rooms')
        .doc(_chatRoomId(ownUid, otherUserId))
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> markMessagesSeen(
    String otherUserId,
    Iterable<MessageModel> messages,
  ) async {
    final ownUid = currentUserId;
    if (ownUid.isEmpty) return;
    final unread = messages
        .where(
          (message) =>
              message.receiverId == ownUid &&
              message.senderId == otherUserId &&
              message.status == MessageStatus.delivered,
        )
        .toList();
    if (unread.isEmpty) return;
    final room = _firestore
        .collection('chat_rooms')
        .doc(_chatRoomId(ownUid, otherUserId));

    for (var offset = 0; offset < unread.length; offset += 500) {
      final batch = _firestore.batch();
      final end = offset + 500 < unread.length ? offset + 500 : unread.length;
      for (final message in unread.sublist(offset, end)) {
        batch.update(room.collection('messages').doc(message.id), {
          'status': MessageStatus.seen.name,
          'seenAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<String?> getUidByEmail(String email) async {
    final result = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (result.docs.isEmpty) return null;
    return result.docs.first.data()['uid'] as String? ?? result.docs.first.id;
  }

  String _chatRoomId(String firstUid, String secondUid) {
    final ids = [firstUid, secondUid]..sort();
    return ids.join('_');
  }
}
