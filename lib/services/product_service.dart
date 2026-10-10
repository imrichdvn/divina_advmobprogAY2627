import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

class ProductService {
  ProductService({
    http.Client? client,
    Duration retryDelay = const Duration(milliseconds: 400),
    Duration requestTimeout = const Duration(seconds: 15),
    int maxAttempts = 3,
  }) : _client = client ?? http.Client(),
       _retryDelay = retryDelay,
       _requestTimeout = requestTimeout,
       _maxAttempts = maxAttempts;

  final http.Client _client;
  final Duration _retryDelay;
  final Duration _requestTimeout;
  final int _maxAttempts;

  Future<List<Product>> getAllProducts() async {
    final response = await _get(Uri.parse('$apiHost/products?limit=0'));
    _requireSuccess(response, 'load products');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['products'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  Future<Product> getProductById(int id) async {
    final response = await _get(Uri.parse('$apiHost/products/$id'));
    _requireSuccess(response, 'load product $id');
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<http.Response> _get(Uri uri) async {
    if (_maxAttempts < 1) {
      throw ArgumentError.value(_maxAttempts, 'maxAttempts', 'must be positive');
    }

    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await _client.get(uri).timeout(_requestTimeout);
      } on http.ClientException catch (error) {
        lastError = error;
      } on TimeoutException catch (error) {
        lastError = error;
      }

      if (attempt < _maxAttempts) {
        await Future<void>.delayed(_retryDelay * attempt);
      }
    }

    throw ProductConnectionException(uri: uri, cause: lastError!);
  }

  void _requireSuccess(http.Response response, String action) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to $action (${response.statusCode})');
    }
  }
}

class ProductConnectionException implements Exception {
  const ProductConnectionException({required this.uri, required this.cause});

  final Uri uri;
  final Object cause;

  @override
  String toString() {
    return 'Please check your internet connection and try again. '
        'Could not reach ${uri.host}.';
  }
}
