import 'dart:convert';

import 'package:divina_advmobprog/services/product_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('getAllProducts requests the complete DummyJSON catalog', () async {
    late Uri requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'products': [
            {
              'id': 1,
              'title': 'First product',
              'description': '',
              'category': 'sample',
              'price': 10,
              'thumbnail': '',
            },
            {
              'id': 194,
              'title': 'Last product',
              'description': '',
              'category': 'sample',
              'price': 20,
              'thumbnail': '',
            },
          ],
          'total': 194,
          'skip': 0,
          'limit': 0,
        }),
        200,
      );
    });

    final products = await ProductService(client: client).getAllProducts();

    expect(requestedUri.toString(), 'https://dummyjson.com/products?limit=0');
    expect(products, hasLength(2));
    expect(products.first.title, 'First product');
    expect(products.last.id, 194);
  });
}
