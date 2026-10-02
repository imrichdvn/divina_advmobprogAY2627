import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

final ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  UserService({
    http.Client? client,
    SharedPreferences? preferences,
    firebase.FirebaseAuth? firebaseAuth,
  }) : _client = client ?? http.Client(),
       _preferences = preferences,
       _providedFirebaseAuth = firebaseAuth;

  final http.Client _client;
  final SharedPreferences? _preferences;
  final firebase.FirebaseAuth? _providedFirebaseAuth;

  firebase.FirebaseAuth get _firebaseAuth =>
      _providedFirebaseAuth ?? firebase.FirebaseAuth.instance;

  bool get isFirebaseConfigured =>
      _providedFirebaseAuth != null || Firebase.apps.isNotEmpty;

  firebase.User? get currentUser {
    if (!isFirebaseConfigured) return null;
    return _firebaseAuth.currentUser;
  }

  Stream<firebase.User?> get authStateChanges {
    if (!isFirebaseConfigured) return const Stream.empty();
    return _firebaseAuth.authStateChanges();
  }

  Future<firebase.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    _requireFirebase();
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _saveFirebaseUser(credential.user);
      return credential;
    } on firebase.FirebaseAuthException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  Future<firebase.UserCredential> createAccount({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
    int age = 0,
    String contactNo = '',
    String username = '',
  }) async {
    _requireFirebase();
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final displayName = username.trim().isEmpty
          ? '$firstName $lastName'.trim()
          : username.trim();
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();
      await _saveFirebaseUser(
        _firebaseAuth.currentUser ?? credential.user,
        firstName: firstName,
        lastName: lastName,
        age: age,
        contactNo: contactNo,
        username: username,
      );
      return credential;
    } on firebase.FirebaseAuthException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  Future<void> signOut() async {
    if (isFirebaseConfigured) await _firebaseAuth.signOut();
    await _clearSession();
  }

  Future<void> updateUsername({required String username}) async {
    _requireFirebase();
    final normalized = username.trim();
    if (normalized.isEmpty) throw Exception('Username cannot be empty.');
    final user = _requireCurrentUser();
    try {
      await user.updateDisplayName(normalized);
      await user.reload();
      await (await _getPreferences()).setString('username', normalized);
      await _updateFirestoreProfile({'username': normalized});
    } on firebase.FirebaseAuthException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final user = _requireCurrentUser();
    try {
      final credential = firebase.EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .delete();
      }
      await user.delete();
      await _clearSession();
    } on firebase.FirebaseAuthException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final user = _requireCurrentUser();
    try {
      final credential = firebase.EmailAuthProvider.credential(
        email: email.trim(),
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on firebase.FirebaseAuthException catch (error) {
      throw Exception(_firebaseMessage(error));
    }
  }

  Future<Map<String, dynamic>> signInWithFirebase(
    String email,
    String password,
  ) async {
    await signIn(email: email, password: password);
    return getUserData();
  }

  Future<Map<String, dynamic>> createFirebaseAccount({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
    required String email,
    required String password,
  }) async {
    await createAccount(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      age: age,
      contactNo: contactNo,
      username: username,
    );
    return getUserData();
  }

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final localAccount = await _findLocalAccount(username);
    if (localAccount != null) {
      final salt = localAccount['salt'] as String? ?? '';
      final savedHash = localAccount['passwordHash'] as String? ?? '';
      if (salt.isEmpty || savedHash != _passwordHash(password, salt)) {
        throw Exception('Invalid username or password.');
      }
      final userData = Map<String, dynamic>.from(localAccount['user'] as Map)
        ..['loginType'] = LoginType.dummyJson.storageValue;
      await _clearSession();
      await saveUserData(userData);
      await (await _getPreferences()).setBool('registeredSession', true);
      return userData;
    }

    final response = await _client.post(
      Uri.parse('$apiHost/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );
    if (response.statusCode != 200) throw Exception(response.body);
    final data = jsonDecode(response.body) as Map<String, dynamic>
      ..['loginType'] = LoginType.dummyJson.storageValue;
    await saveUserData(data);
    return data;
  }

  Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String password,
    int age = 0,
    String contactNo = '',
  }) async {
    final normalizedUsername = username.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final accounts = await _getLocalAccounts();
    if (accounts.any(
      (account) =>
          (account['username'] as String? ?? '').toLowerCase() ==
              normalizedUsername.toLowerCase() ||
          (account['email'] as String? ?? '').toLowerCase() == normalizedEmail,
    )) {
      throw Exception('An account with this username or email already exists.');
    }

    final requestBody = <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': normalizedEmail,
      'username': normalizedUsername,
      'password': password,
      if (age > 0) 'age': age,
      if (contactNo.trim().isNotEmpty) 'phone': contactNo.trim(),
    };
    final response = await _client.post(
      Uri.parse('$apiHost/users/add'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body);
    }

    final userData = jsonDecode(response.body) as Map<String, dynamic>;
    final userId = (userData['id'] as num?)?.toInt() ?? 0;
    if (userId <= 0) throw Exception('The server returned an invalid user.');
    var localUserId = userId;
    for (final account in accounts) {
      final savedUser = account['user'];
      if (savedUser is Map) {
        final savedId = (savedUser['id'] as num?)?.toInt() ?? 0;
        localUserId = max(localUserId, savedId + 1);
      }
    }

    final accountUserData = <String, dynamic>{
      ...userData,
      'id': localUserId,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': normalizedEmail,
      'username': normalizedUsername,
      'age': age,
      'contactNo': contactNo.trim(),
      'loginType': LoginType.dummyJson.storageValue,
    }..remove('password');
    final salt = _newSalt();
    accounts.add({
      'username': normalizedUsername,
      'email': normalizedEmail,
      'salt': salt,
      'passwordHash': _passwordHash(password, salt),
      'user': accountUserData,
    });
    final preferences = await _getPreferences();
    await preferences.setString('local_accounts', jsonEncode(accounts));
    await _clearSession();
    await saveUserData(accountUserData);
    await preferences.setBool('registeredSession', true);
    return accountUserData;
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final preferences = await _getPreferences();
    final user = User.fromJson(userData);
    await preferences.setInt('id', user.id);
    await preferences.setString('username', user.username);
    await preferences.setString('email', user.email);
    await preferences.setString('firstName', user.firstName);
    await preferences.setString('lastName', user.lastName);
    await preferences.setString('gender', user.gender);
    await preferences.setString('image', user.image);
    await preferences.setInt('age', user.age);
    await preferences.setString('contactNo', user.contactNo);
    await preferences.setString('loginType', user.loginType.storageValue);
    final accessToken =
        userData['accessToken'] as String? ??
        userData['token'] as String? ??
        user.accessToken;
    await preferences.setString('accessToken', accessToken);
    await preferences.setString('refreshToken', user.refreshToken);
    if (accessToken.isNotEmpty) {
      await preferences.setString('token', accessToken);
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final preferences = await _getPreferences();
    final loginType = LoginType.fromValue(preferences.getString('loginType'));
    if (loginType == LoginType.firebase && currentUser != null) {
      await _saveFirebaseUser(currentUser);
    }
    return {
      'id': preferences.getInt('id') ?? 0,
      'username': preferences.getString('username') ?? '',
      'email': preferences.getString('email') ?? '',
      'firstName': preferences.getString('firstName') ?? '',
      'lastName': preferences.getString('lastName') ?? '',
      'gender': preferences.getString('gender') ?? '',
      'image': preferences.getString('image') ?? '',
      'age': preferences.getInt('age') ?? 0,
      'contactNo': preferences.getString('contactNo') ?? '',
      'loginType':
          preferences.getString('loginType') ??
          LoginType.dummyJson.storageValue,
      'accessToken':
          preferences.getString('accessToken') ??
          preferences.getString('token') ??
          '',
      'refreshToken': preferences.getString('refreshToken') ?? '',
      'token':
          preferences.getString('token') ??
          preferences.getString('accessToken') ??
          '',
    };
  }

  Future<User> getUser() async => User.fromJson(await getUserData());

  Future<bool> isLoggedIn() async {
    final preferences = await _getPreferences();
    final loginType = LoginType.fromValue(preferences.getString('loginType'));
    if (loginType == LoginType.firebase) return currentUser != null;
    final token =
        preferences.getString('accessToken') ?? preferences.getString('token');
    return (token != null && token.isNotEmpty) ||
        (preferences.getBool('registeredSession') ?? false);
  }

  Future<void> logout() => signOut();

  Future<void> _saveFirebaseUser(
    firebase.User? firebaseUser, {
    String? firstName,
    String? lastName,
    int? age,
    String? contactNo,
    String? username,
  }) async {
    if (firebaseUser == null) {
      throw Exception('Firebase did not return a user.');
    }
    final preferences = await _getPreferences();
    final token = await firebaseUser.getIdToken() ?? '';
    final storedFirstName =
        firstName ?? preferences.getString('firstName') ?? '';
    final storedLastName = lastName ?? preferences.getString('lastName') ?? '';
    final storedUsername = username?.trim().isNotEmpty == true
        ? username!.trim()
        : (firebaseUser.displayName ??
              preferences.getString('username') ??
              firebaseUser.email?.split('@').first ??
              '');
    final userData = <String, dynamic>{
      'id': _stableFirebaseId(firebaseUser.uid),
      'username': storedUsername,
      'email': firebaseUser.email ?? '',
      'firstName': storedFirstName,
      'lastName': storedLastName,
      'image': firebaseUser.photoURL ?? '',
      'age': age ?? preferences.getInt('age') ?? 0,
      'contactNo': contactNo ?? preferences.getString('contactNo') ?? '',
      'loginType': LoginType.firebase.storageValue,
      'accessToken': token,
      'token': token,
    };
    await saveUserData(userData);
    if (Firebase.apps.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(firebaseUser.uid)
          .set({
            'uid': firebaseUser.uid,
            'email': firebaseUser.email?.toLowerCase() ?? '',
            'firstName': storedFirstName,
            'lastName': storedLastName,
            'username': storedUsername,
            'image': firebaseUser.photoURL ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
  }

  Future<void> _updateFirestoreProfile(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null || Firebase.apps.isEmpty) return;
    await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
      ...data,
      'uid': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  int _stableFirebaseId(String uid) {
    var hash = 17;
    for (final unit in uid.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return max(1, hash);
  }

  void _requireFirebase() {
    if (!isFirebaseConfigured) {
      throw Exception(
        'Firebase is not configured yet. Run flutterfire configure after '
        'accepting the Google Cloud Terms of Service.',
      );
    }
  }

  firebase.User _requireCurrentUser() {
    _requireFirebase();
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('Sign in with Firebase first.');
    return user;
  }

  String _firebaseMessage(firebase.FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Invalid email or password.',
      'email-already-in-use' => 'An account already uses this email address.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' => 'Use a stronger password with at least 6 characters.',
      'requires-recent-login' =>
        'For security, sign in again before changing this account.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      _ => error.message ?? 'Firebase authentication failed.',
    };
  }

  Future<void> _clearSession() async {
    final preferences = await _getPreferences();
    for (final key in [
      'id',
      'username',
      'email',
      'firstName',
      'lastName',
      'gender',
      'image',
      'age',
      'contactNo',
      'loginType',
      'accessToken',
      'refreshToken',
      'token',
      'registeredSession',
    ]) {
      await preferences.remove(key);
    }
  }

  Future<Map<String, dynamic>?> _findLocalAccount(String username) async {
    final normalizedUsername = username.trim().toLowerCase();
    for (final account in await _getLocalAccounts()) {
      if ((account['username'] as String? ?? '').toLowerCase() ==
          normalizedUsername) {
        return account;
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _getLocalAccounts() async {
    final preferences = await _getPreferences();
    final savedAccounts = preferences.getString('local_accounts');
    if (savedAccounts == null) return [];
    try {
      final decoded = jsonDecode(savedAccounts);
      if (decoded is! List) throw const FormatException();
      return decoded
          .whereType<Map>()
          .map((account) => Map<String, dynamic>.from(account))
          .toList();
    } on FormatException {
      await preferences.remove('local_accounts');
      return [];
    } on TypeError {
      await preferences.remove('local_accounts');
      return [];
    }
  }

  String _newSalt() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  String _passwordHash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  Future<SharedPreferences> _getPreferences() async {
    return _preferences ?? SharedPreferences.getInstance();
  }
}
