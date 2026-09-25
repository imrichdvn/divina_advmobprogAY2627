import 'package:divina_advmobprog/models/cart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cart', () {
    test('parses DummyJSON cart totals and products', () {
      final cart = Cart.fromJson({
        'id': 7,
        'products': [
          {
            'id': 12,
            'title': 'Sample product',
            'price': 25,
            'quantity': 2,
            'total': 50,
            'discountPercentage': 10,
            'discountedTotal': 45,
            'thumbnail': 'https://example.com/product.png',
          },
        ],
        'total': 50,
        'discountedTotal': 45,
        'userId': 1,
        'totalProducts': 1,
        'totalQuantity': 2,
      });

      expect(cart.id, 7);
      expect(cart.userId, 1);
      expect(cart.products.single.title, 'Sample product');
      expect(cart.discountedTotal, 45);
    });

    test('recalculates totals when quantity changes', () {
      final cart = Cart.fromJson({
        'id': 7,
        'products': [
          {
            'id': 12,
            'title': 'Sample product',
            'price': 25,
            'quantity': 2,
            'discountPercentage': 10,
            'thumbnail': '',
          },
        ],
        'userId': 1,
      });

      final updated = cart.updateQuantity(12, 3);

      expect(updated.products.single.quantity, 3);
      expect(updated.total, 75);
      expect(updated.discountedTotal, 67.5);
      expect(updated.totalQuantity, 3);
    });

    test('removes a product when its quantity reaches zero', () {
      final cart = Cart.fromJson({
        'id': 7,
        'products': [
          {
            'id': 12,
            'title': 'Sample product',
            'price': 25,
            'quantity': 1,
            'discountPercentage': 10,
            'thumbnail': '',
          },
        ],
        'userId': 1,
      });

      final updated = cart.updateQuantity(12, 0);

      expect(updated.products, isEmpty);
      expect(updated.total, 0);
      expect(updated.discountedTotal, 0);
      expect(updated.totalProducts, 0);
      expect(updated.totalQuantity, 0);
    });
  });
}
