import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartService {
  CartService({http.Client? client, SharedPreferences? preferences})
    : _client = client ?? http.Client(),
      _preferences = preferences;

  final http.Client _client;
  final SharedPreferences? _preferences;

  Future<Cart> getLocalCart(int userId) async {
    final preferences = await _getPreferences();
    final savedCart = preferences.getString(_localCartKey(userId));
    if (savedCart == null) return Cart.empty(userId: userId);

    try {
      final cart = Cart.fromJson(jsonDecode(savedCart) as Map<String, dynamic>);
      return cart.userId == userId ? cart : Cart.empty(userId: userId);
    } on FormatException {
      await preferences.remove(_localCartKey(userId));
      return Cart.empty(userId: userId);
    } on TypeError {
      await preferences.remove(_localCartKey(userId));
      return Cart.empty(userId: userId);
    }
  }

  Future<void> saveLocalCart(Cart cart) async {
    final preferences = await _getPreferences();
    await preferences.setString(
      _localCartKey(cart.userId),
      jsonEncode(cart.toJson()),
    );
  }

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

  Cart addProductLocally({required Cart cart, required Product product}) {
    final existingProduct = cart.products
        .where((item) => item.id == product.id)
        .firstOrNull;
    if (existingProduct != null) {
      return cart.updateQuantity(product.id, existingProduct.quantity + 1);
    }

    final total = product.price;
    final discountedTotal = total * (1 - product.discountPercentage / 100);
    final cartProduct = CartProduct(
      id: product.id,
      title: product.title,
      price: product.price,
      quantity: 1,
      total: total,
      discountPercentage: product.discountPercentage,
      discountedTotal: discountedTotal,
      thumbnail: product.thumbnail,
    );
    return cart.copyWithProducts([...cart.products, cartProduct]);
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

  String _localCartKey(int userId) => 'local_cart_$userId';

  Future<SharedPreferences> _getPreferences() async {
    return _preferences ?? SharedPreferences.getInstance();
  }
}
