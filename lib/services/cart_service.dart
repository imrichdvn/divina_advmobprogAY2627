import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartService {
  CartService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Cart>> getAllCarts() async {
    final response = await _client.get(Uri.parse('$apiHost/carts'));
    _requireSuccess(response, 'load carts');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseCarts(data);
  }

  Future<Cart> getCartById(int cartId) async {
    final response = await _client.get(Uri.parse('$apiHost/carts/$cartId'));
    _requireSuccess(response, 'load cart $cartId');
    return Cart.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Cart> getCartByUserId(int userId) async {
    final response = await _client.get(
      Uri.parse('$apiHost/carts/user/$userId'),
    );
    _requireSuccess(response, 'load cart for user $userId');
    final carts = _parseCarts(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    return carts.isEmpty ? Cart.empty(userId: userId) : carts.first;
  }

  Future<Cart> addCart({
    required int userId,
    required Map<int, int> productQuantities,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiHost/carts/add'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': productQuantities.entries
            .map((entry) => {'id': entry.key, 'quantity': entry.value})
            .toList(),
      }),
    );
    _requireSuccess(response, 'add cart');
    return Cart.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Cart> addProductToCart({
    required Cart cart,
    required Product product,
  }) {
    final quantities = {
      for (final item in cart.products) item.id: item.quantity,
    };
    quantities.update(
      product.id,
      (quantity) => quantity + 1,
      ifAbsent: () => 1,
    );
    return addCart(userId: cart.userId, productQuantities: quantities);
  }

  List<Cart> _parseCarts(Map<String, dynamic> data) {
    return (data['carts'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Cart.fromJson)
        .toList();
  }

  void _requireSuccess(http.Response response, String action) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to $action (${response.statusCode})');
    }
  }
}
