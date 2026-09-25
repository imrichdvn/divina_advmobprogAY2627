import 'dart:convert';

import 'package:divina_advmobprog/models/user.dart';
import 'package:divina_advmobprog/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'loginUser sends expiry and saves profile and token preferences',
    () async {
      late http.Request request;
      final client = MockClient((capturedRequest) async {
        request = capturedRequest;
        return http.Response(
          jsonEncode({
            'id': 7,
            'username': 'sample-user',
            'email': 'sample@example.com',
            'firstName': 'Sample',
            'lastName': 'User',
            'gender': 'female',
            'image': 'https://example.com/avatar.png',
            'accessToken': 'temporary-token',
            'refreshToken': 'temporary-refresh-token',
          }),
          200,
        );
      });

      final service = UserService(client: client);
      final userData = await service.loginUser('sample-user', 'not-saved');
      final preferences = await SharedPreferences.getInstance();

      expect(request.url.toString(), 'https://dummyjson.com/auth/login');
      expect(request.method, 'POST');
      expect(jsonDecode(request.body), {
        'username': 'sample-user',
        'password': 'not-saved',
        'expiresInMins': 60,
      });
      expect(User.fromJson(userData).fullName, 'Sample User');
      expect(preferences.getInt('id'), 7);
      expect(preferences.getString('username'), 'sample-user');
      expect(preferences.getString('email'), 'sample@example.com');
      expect(preferences.getString('firstName'), 'Sample');
      expect(preferences.getString('lastName'), 'User');
      expect(preferences.getString('gender'), 'female');
      expect(preferences.getString('image'), 'https://example.com/avatar.png');
      expect(preferences.getString('accessToken'), 'temporary-token');
      expect(preferences.getString('refreshToken'), 'temporary-refresh-token');
      expect(preferences.getString('token'), 'temporary-token');
      expect(preferences.getString('password'), isNull);
    },
  );

  test(
    'saved profile and token restore and logout clears preferences',
    () async {
      final service = UserService();
      await service.saveUserData({
        'id': 12,
        'username': 'returning-user',
        'email': 'returning@example.com',
        'firstName': 'Returning',
        'lastName': 'User',
        'gender': 'male',
        'image': '',
        'token': 'generic-token',
      });

      expect(await service.isLoggedIn(), isTrue);
      final restoredData = await service.getUserData();
      expect(restoredData['id'], 12);
      expect(restoredData['accessToken'], 'generic-token');
      expect(restoredData['token'], 'generic-token');
      expect((await service.getUser()).fullName, 'Returning User');

      await service.logout();
      expect(await service.isLoggedIn(), isFalse);
      expect(await service.getUserData(), {
        'id': 0,
        'username': '',
        'email': '',
        'firstName': '',
        'lastName': '',
        'gender': '',
        'image': '',
        'accessToken': '',
        'refreshToken': '',
        'token': '',
      });
    },
  );

  test('loginUser returns the API error for invalid credentials', () async {
    final client = MockClient(
      (_) async =>
          http.Response(jsonEncode({'message': 'Invalid credentials'}), 400),
    );

    await expectLater(
      UserService(client: client).loginUser('wrong-user', 'wrong-password'),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Invalid credentials'),
        ),
      ),
    );
    expect(await UserService().isLoggedIn(), isFalse);
  });
}
