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

  test('signIn authenticates and persists only the user profile', () async {
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

    final user = await UserService(
      client: client,
    ).signIn(username: 'sample-user', password: 'not-saved');
    final preferences = await SharedPreferences.getInstance();
    final savedProfile = preferences.getString('saved_user')!;

    expect(request.url.toString(), 'https://dummyjson.com/auth/login');
    expect(request.method, 'POST');
    expect(jsonDecode(request.body), {
      'username': 'sample-user',
      'password': 'not-saved',
    });
    expect(user.fullName, 'Sample User');
    expect(jsonDecode(savedProfile), {
      'id': 7,
      'username': 'sample-user',
      'email': 'sample@example.com',
      'firstName': 'Sample',
      'lastName': 'User',
      'gender': 'female',
      'image': 'https://example.com/avatar.png',
    });
    expect(savedProfile, isNot(contains('temporary-token')));
    expect(savedProfile, isNot(contains('not-saved')));
  });

  test(
    'saved profile restores across launches and signOut clears it',
    () async {
      final service = UserService();
      const user = User(
        id: 12,
        username: 'returning-user',
        email: 'returning@example.com',
        firstName: 'Returning',
        lastName: 'User',
        gender: 'male',
        image: '',
      );

      await service.saveSession(user);
      expect((await service.getSavedUser())?.toJson(), user.toJson());

      await service.signOut();
      expect(await service.getSavedUser(), isNull);
    },
  );

  test('signIn returns the API error for invalid credentials', () async {
    final client = MockClient(
      (_) async =>
          http.Response(jsonEncode({'message': 'Invalid credentials'}), 400),
    );

    await expectLater(
      UserService(
        client: client,
      ).signIn(username: 'wrong-user', password: 'wrong-password'),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Invalid credentials'),
        ),
      ),
    );
    expect(
      (await SharedPreferences.getInstance()).getString('saved_user'),
      isNull,
    );
  });
}
