import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

class ProductService {
  ProductService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Product>> getAllProducts() async {
    final response = await _client.get(Uri.parse('$apiHost/products?limit=0'));
    _requireSuccess(response, 'load products');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['products'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  Future<Product> getProductById(int id) async {
    final response = await _client.get(Uri.parse('$apiHost/products/$id'));
    _requireSuccess(response, 'load product $id');
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void _requireSuccess(http.Response response, String action) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to $action (${response.statusCode})');
    }
  }
}
