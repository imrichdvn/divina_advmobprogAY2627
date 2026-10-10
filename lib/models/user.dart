enum LoginType {
  dummyJson,
  firebase;

  String get storageValue => name;

  String get label => this == LoginType.firebase ? 'Firebase' : 'DummyJSON';

  static LoginType fromValue(Object? value) {
    return value == firebase.name ? firebase : dummyJson;
  }
}

class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    this.age = 0,
    this.contactNo = '',
    this.loginType = LoginType.dummyJson,
    this.accessToken = '',
    this.refreshToken = '',
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final int age;
  final String contactNo;
  final LoginType loginType;
  final String accessToken;
  final String refreshToken;

  String get fullName => '$firstName $lastName'.trim();

  bool get usesLocalCart =>
      loginType == LoginType.firebase || accessToken.isEmpty;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      image: json['image'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      contactNo: json['contactNo'] as String? ?? json['phone'] as String? ?? '',
      loginType: LoginType.fromValue(json['loginType']),
      accessToken:
          json['accessToken'] as String? ?? json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'gender': gender,
    'image': image,
    'age': age,
    'contactNo': contactNo,
    'loginType': loginType.storageValue,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}
