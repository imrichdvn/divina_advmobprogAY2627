import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  UserService({http.Client? client, SharedPreferences? preferences})
    : _client = client ?? http.Client(),
      _preferences = preferences;

  final http.Client _client;
  final SharedPreferences? _preferences;

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
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
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await saveUserData(data);
    return data;
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
    return {
      'id': preferences.getInt('id') ?? 0,
      'username': preferences.getString('username') ?? '',
      'email': preferences.getString('email') ?? '',
      'firstName': preferences.getString('firstName') ?? '',
      'lastName': preferences.getString('lastName') ?? '',
      'gender': preferences.getString('gender') ?? '',
      'image': preferences.getString('image') ?? '',
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

  Future<User> getUser() async {
    return User.fromJson(await getUserData());
  }

  Future<bool> isLoggedIn() async {
    final preferences = await _getPreferences();
    final token =
        preferences.getString('accessToken') ?? preferences.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await (await _getPreferences()).clear();
  }

  Future<SharedPreferences> _getPreferences() async {
    return _preferences ?? SharedPreferences.getInstance();
  }
}
