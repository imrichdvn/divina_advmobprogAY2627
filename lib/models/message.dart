import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sending, delivered, seen }

class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.status,
    this.clientMessageId = '',
    this.seenAt,
  });

  final String id;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final MessageStatus status;
  final String clientMessageId;
  final Timestamp? seenAt;

  factory MessageModel.fromMap(String documentId, Map<String, dynamic> map) {
    return MessageModel(
      id: documentId,
      senderId: map['senderId'] as String? ?? '',
      senderEmail: map['senderEmail'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      message: map['message'] as String? ?? '',
      timestamp: map['timestamp'] as Timestamp? ?? Timestamp.now(),
      status: MessageStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => MessageStatus.delivered,
      ),
      clientMessageId: map['clientMessageId'] as String? ?? '',
      seenAt: map['seenAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderEmail': senderEmail,
    'receiverId': receiverId,
    'message': message,
    'timestamp': timestamp,
    'status': status.name,
    'clientMessageId': clientMessageId,
    if (seenAt != null) 'seenAt': seenAt,
  };
}
