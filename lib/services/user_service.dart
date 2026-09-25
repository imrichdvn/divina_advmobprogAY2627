import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  UserService({http.Client? client, SharedPreferences? preferences})
    : _client = client ?? http.Client(),
      _preferences = preferences;

  static const _savedUserKey = 'saved_user';

  final http.Client _client;
  final SharedPreferences? _preferences;

  Future<User> signIn({
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiHost/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message'] as String? ?? 'Sign in failed.'
          : 'Sign in failed.';
      throw Exception(message);
    }

    final user = User.fromJson(decoded as Map<String, dynamic>);
    if (user.id <= 0) throw Exception('The server returned an invalid user.');
    await saveSession(user);
    return user;
  }

  Future<User?> getSavedUser() async {
    final preferences = await _getPreferences();
    final savedUser = preferences.getString(_savedUserKey);
    if (savedUser == null) return null;

    try {
      return User.fromJson(jsonDecode(savedUser) as Map<String, dynamic>);
    } on FormatException {
      await preferences.remove(_savedUserKey);
      return null;
    } on TypeError {
      await preferences.remove(_savedUserKey);
      return null;
    }
  }

  Future<void> saveSession(User user) async {
    await (await _getPreferences()).setString(
      _savedUserKey,
      jsonEncode(user.toJson()),
    );
  }

  Future<void> signOut() async {
    await (await _getPreferences()).remove(_savedUserKey);
  }

  Future<SharedPreferences> _getPreferences() async {
    return _preferences ?? SharedPreferences.getInstance();
  }
}
