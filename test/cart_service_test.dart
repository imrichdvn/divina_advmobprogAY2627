import 'dart:convert';

import 'package:divina_advmobprog/services/cart_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'getCartByUserId requests one user and returns the first cart',
    () async {
      late Uri requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'carts': [
              {
                'id': 19,
                'products': <Map<String, dynamic>>[],
                'total': 0,
                'discountedTotal': 0,
                'userId': 5,
                'totalProducts': 0,
                'totalQuantity': 0,
              },
            ],
          }),
          200,
        );
      });

      final cart = await CartService(client: client).getCartByUserId(5);

      expect(requestedUri.toString(), 'https://dummyjson.com/carts/user/5');
      expect(cart.id, 19);
      expect(cart.userId, 5);
    },
  );

  test('addCart posts product ids and quantities to carts/add', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({
          'id': 51,
          'products': [
            {
              'id': 12,
              'title': 'Sample product',
              'price': 25,
              'quantity': 3,
              'total': 75,
              'discountPercentage': 10,
              'discountedTotal': 67.5,
              'thumbnail': '',
            },
          ],
          'total': 75,
          'discountedTotal': 67.5,
          'userId': 1,
          'totalProducts': 1,
          'totalQuantity': 3,
        }),
        201,
      );
    });

    final cart = await CartService(
      client: client,
    ).addCart(userId: 1, productQuantities: {12: 3});

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.toString(), 'https://dummyjson.com/carts/add');
    expect(capturedRequest.headers['content-type'], 'application/json');
    expect(jsonDecode(capturedRequest.body), {
      'userId': 1,
      'products': [
        {'id': 12, 'quantity': 3},
      ],
    });
    expect(cart.id, 51);
    expect(cart.totalQuantity, 3);
  });
}
