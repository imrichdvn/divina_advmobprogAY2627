import 'dart:convert';

import 'package:divina_advmobprog/models/cart.dart';
import 'package:divina_advmobprog/models/product.dart';
import 'package:divina_advmobprog/services/cart_service.dart';
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

  test('addProductLocally adds and increments products in a demo cart', () {
    final service = CartService(
      client: MockClient((_) async => http.Response('', 500)),
    );
    const product = Product(
      id: 42,
      title: 'Demo product',
      description: '',
      category: 'sample',
      price: 50,
      discountPercentage: 20,
      rating: 4,
      stock: 10,
      brand: 'Demo',
      images: [],
      thumbnail: 'https://example.com/demo.png',
    );
    final emptyCart = Cart.empty(userId: 209);

    final firstAdd = service.addProductLocally(
      cart: emptyCart,
      product: product,
    );
    final secondAdd = service.addProductLocally(
      cart: firstAdd,
      product: product,
    );

    expect(firstAdd.userId, 209);
    expect(firstAdd.products.single.quantity, 1);
    expect(firstAdd.discountedTotal, 40);
    expect(secondAdd.products.single.quantity, 2);
    expect(secondAdd.totalQuantity, 2);
    expect(secondAdd.total, 100);
    expect(secondAdd.discountedTotal, 80);
  });

  test('local cart survives logout and a new CartService instance', () async {
    final service = CartService(
      client: MockClient((_) async => http.Response('', 500)),
    );
    const product = Product(
      id: 42,
      title: 'Saved demo product',
      description: '',
      category: 'sample',
      price: 30,
      discountPercentage: 10,
      rating: 4,
      stock: 10,
      brand: 'Demo',
      images: [],
      thumbnail: 'https://example.com/saved.png',
    );
    final cart = service.addProductLocally(
      cart: Cart.empty(userId: 209),
      product: product,
    );
    await service.saveLocalCart(cart);

    await UserService().logout();

    final returningService = CartService(
      client: MockClient((_) async => http.Response('', 500)),
    );
    final restoredCart = await returningService.getLocalCart(209);

    expect(restoredCart.userId, 209);
    expect(restoredCart.products.single.title, 'Saved demo product');
    expect(restoredCart.products.single.quantity, 1);
    expect(restoredCart.discountedTotal, 27);
  });
}
