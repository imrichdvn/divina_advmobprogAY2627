class ChatUser {
  const ChatUser({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.image = '',
  });

  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String image;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    if (name.isNotEmpty) return name;
    if (username.isNotEmpty) return username;
    return email.split('@').first;
  }

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  factory ChatUser.fromMap(String documentId, Map<String, dynamic> map) {
    return ChatUser(
      uid: map['uid'] as String? ?? documentId,
      email: map['email'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      username: map['username'] as String? ?? '',
      image: map['image'] as String? ?? '',
    );
  }
}
