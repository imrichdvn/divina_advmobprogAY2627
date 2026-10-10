import 'package:divina_advmobprog/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  User createUser({required LoginType loginType, String accessToken = ''}) {
    return User(
      id: 21,
      username: 'sample',
      email: 'sample@example.com',
      firstName: 'Sample',
      lastName: 'User',
      gender: '',
      image: '',
      loginType: loginType,
      accessToken: accessToken,
    );
  }

  test('Firebase carts are local even when the Firebase token exists', () {
    final user = createUser(
      loginType: LoginType.firebase,
      accessToken: 'firebase-id-token',
    );

    expect(user.usesLocalCart, isTrue);
  });

  test('DummyJSON accounts with API tokens use remote carts', () {
    final user = createUser(
      loginType: LoginType.dummyJson,
      accessToken: 'dummyjson-api-token',
    );

    expect(user.usesLocalCart, isFalse);
  });

  test('local demo accounts use local carts', () {
    final user = createUser(loginType: LoginType.dummyJson);

    expect(user.usesLocalCart, isTrue);
  });
}
