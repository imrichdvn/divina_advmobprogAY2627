import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';
import 'detail_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({
    super.key,
    this.cart,
    this.userId = demoUserId,
    this.onCartChanged,
  });

  final Cart? cart;
  final int userId;
  final ValueChanged<Cart>? onCartChanged;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _addingProductIds = {};

  List<Product> _products = [];
  Cart? _localCart;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _localCart = widget.cart;
    _loadProducts();
  }

  @override
  void didUpdateWidget(covariant ProductScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cart != oldWidget.cart) {
      _localCart = widget.cart;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _productService.getAllProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addToCart(Product product) async {
    setState(() => _addingProductIds.add(product.id));
    try {
      final currentCart =
          widget.cart ?? _localCart ?? Cart.empty(userId: widget.userId);

      // Enhancement 3: pass Product values to the documented /carts/add API.
      final updatedCart = await _cartService.addProductToCart(
        cart: currentCart,
        product: product,
      );
      if (!mounted) return;
      setState(() => _localCart = updatedCart);
      widget.onCartChanged?.call(updatedCart);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${product.title} added to cart')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add product: $error')));
    } finally {
      if (mounted) {
        setState(() => _addingProductIds.remove(product.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredProducts = _products.where((product) {
      return product.title.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadProducts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
              sliver: SliverToBoxAdapter(
                child: Text(
                  _loading
                      ? 'Loading the complete catalog...'
                      : '${filteredProducts.length} of ${_products.length} products',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _LoadError(message: _error!, onRetry: _loadProducts),
              )
            else if (filteredProducts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No products found.')),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 0.66,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = filteredProducts[index];
                    return _ProductCard(
                      product: product,
                      isAdding: _addingProductIds.contains(product.id),
                      onAdd: () => _addToCart(product),
                    );
                  }, childCount: filteredProducts.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isAdding,
    required this.onAdd,
  });

  final Product product;
  final bool isAdding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen.fromProduct(product)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8.r),
                child: Image.network(
                  product.thumbnail,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 6.h, 6.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: product.title,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          text: '\$${product.price.toStringAsFixed(2)}',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox.square(
                        dimension: 38.r,
                        child: isAdding
                            ? Padding(
                                padding: EdgeInsets.all(9.r),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                tooltip: 'Add to cart',
                                onPressed: onAdd,
                                icon: const Icon(Icons.add_shopping_cart),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 80.h),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          SizedBox(height: 12.h),
          Text(
            'Unable to load products.\n$message',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
