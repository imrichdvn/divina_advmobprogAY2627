class Cart {
  const Cart({
    required this.id,
    required this.products,
    required this.total,
    required this.discountedTotal,
    required this.userId,
    required this.totalProducts,
    required this.totalQuantity,
  });

  final int id;
  final List<CartProduct> products;
  final double total;
  final double discountedTotal;
  final int userId;
  final int totalProducts;
  final int totalQuantity;

  factory Cart.empty({required int userId}) {
    return Cart(
      id: 0,
      products: const [],
      total: 0,
      discountedTotal: 0,
      userId: userId,
      totalProducts: 0,
      totalQuantity: 0,
    );
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    final products = (json['products'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CartProduct.fromJson)
        .toList();

    return Cart(
      id: (json['id'] as num?)?.toInt() ?? 0,
      products: products,
      total:
          (json['total'] as num?)?.toDouble() ??
          products.fold(0, (sum, product) => sum + product.total),
      discountedTotal:
          (json['discountedTotal'] as num?)?.toDouble() ??
          products.fold(0, (sum, product) => sum + product.discountedTotal),
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      totalProducts:
          (json['totalProducts'] as num?)?.toInt() ?? products.length,
      totalQuantity:
          (json['totalQuantity'] as num?)?.toInt() ??
          products.fold(0, (sum, product) => sum + product.quantity),
    );
  }

  Cart updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      return copyWithProducts(
        products.where((product) => product.id != productId).toList(),
      );
    }

    final updatedProducts = products
        .map(
          (product) => product.id == productId
              ? product.withQuantity(quantity)
              : product,
        )
        .toList();
    return copyWithProducts(updatedProducts);
  }

  Cart copyWithProducts(List<CartProduct> updatedProducts) {
    return Cart(
      id: id,
      products: List.unmodifiable(updatedProducts),
      total: updatedProducts.fold(0, (sum, product) => sum + product.total),
      discountedTotal: updatedProducts.fold(
        0,
        (sum, product) => sum + product.discountedTotal,
      ),
      userId: userId,
      totalProducts: updatedProducts.length,
      totalQuantity: updatedProducts.fold(
        0,
        (sum, product) => sum + product.quantity,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'products': products.map((product) => product.toJson()).toList(),
      'total': total,
      'discountedTotal': discountedTotal,
      'userId': userId,
      'totalProducts': totalProducts,
      'totalQuantity': totalQuantity,
    };
  }
}

class CartProduct {
  const CartProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.total,
    required this.discountPercentage,
    required this.discountedTotal,
    required this.thumbnail,
  });

  final int id;
  final String title;
  final double price;
  final int quantity;
  final double total;
  final double discountPercentage;
  final double discountedTotal;
  final String thumbnail;

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] as num?)?.toDouble() ?? 0;
    final quantity = (json['quantity'] as num?)?.toInt() ?? 0;
    final total = (json['total'] as num?)?.toDouble() ?? price * quantity;
    final discountPercentage =
        (json['discountPercentage'] as num?)?.toDouble() ?? 0;
    final calculatedDiscount = total * (1 - discountPercentage / 100);

    return CartProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      price: price,
      quantity: quantity,
      total: total,
      discountPercentage: discountPercentage,
      discountedTotal:
          (json['discountedTotal'] as num?)?.toDouble() ??
          (json['discountedPrice'] as num?)?.toDouble() ??
          calculatedDiscount,
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }

  CartProduct withQuantity(int newQuantity) {
    final safeQuantity = newQuantity < 1 ? 1 : newQuantity;
    final newTotal = price * safeQuantity;
    return CartProduct(
      id: id,
      title: title,
      price: price,
      quantity: safeQuantity,
      total: newTotal,
      discountPercentage: discountPercentage,
      discountedTotal: newTotal * (1 - discountPercentage / 100),
      thumbnail: thumbnail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'quantity': quantity,
      'total': total,
      'discountPercentage': discountPercentage,
      'discountedTotal': discountedTotal,
      'thumbnail': thumbnail,
    };
  }
}
