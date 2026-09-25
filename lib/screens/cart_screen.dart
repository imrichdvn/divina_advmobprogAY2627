import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';
import 'detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    this.cart,
    this.userId = demoUserId,
    this.onCartChanged,
  });

  final Cart? cart;
  final int userId;
  final ValueChanged<Cart>? onCartChanged;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _service = CartService();
  Cart? _cart;
  bool _loading = false;
  bool _confirming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cart = widget.cart;
    if (_cart == null) {
      _loadUserCart();
    }
  }

  @override
  void didUpdateWidget(covariant CartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cart != null && widget.cart != oldWidget.cart) {
      _cart = widget.cart;
    }
  }

  Future<void> _loadUserCart() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Enhancement 3: load only the cart belonging to the selected user ID.
      final cart = await _service.getCartByUserId(widget.userId);
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _loading = false;
      });
      widget.onCartChanged?.call(cart);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _changeQuantity(CartProduct product, int change) {
    final cart = _cart;
    if (cart == null) return;
    final updatedCart = cart.updateQuantity(
      product.id,
      product.quantity + change,
    );
    setState(() => _cart = updatedCart);
    widget.onCartChanged?.call(updatedCart);
  }

  Future<void> _confirmOrder() async {
    final cart = _cart;
    if (cart == null || cart.products.isEmpty) return;
    setState(() => _confirming = true);
    try {
      // Enhancement 3: send the current product IDs and quantities to /carts/add.
      final confirmedCart = await _service.addCart(
        userId: cart.userId,
        productQuantities: {
          for (final product in cart.products) product.id: product.quantity,
        },
      );
      if (!mounted) return;
      setState(() => _cart = confirmedCart);
      widget.onCartChanged?.call(confirmedCart);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${confirmedCart.id} confirmed')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not confirm order: $error')),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _cart == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _cart == null) {
      return _CartLoadError(message: _error!, onRetry: _loadUserCart);
    }

    final cart = _cart ?? Cart.empty(userId: widget.userId);
    if (cart.products.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadUserCart,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 160.h),
            Icon(Icons.remove_shopping_cart_outlined, size: 64.sp),
            SizedBox(height: 12.h),
            const Center(child: Text('This cart is empty.')),
          ],
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadUserCart,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 20.h),
                itemCount: cart.products.length,
                separatorBuilder: (_, _) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final product = cart.products[index];
                  return _CartItemCard(
                    product: product,
                    onIncrease: () => _changeQuantity(product, 1),
                    onDecrease: () => _changeQuantity(product, -1),
                  );
                },
              ),
            ),
          ),
          _OrderSummary(
            cart: cart,
            confirming: _confirming,
            onConfirm: _confirmOrder,
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.product,
    required this.onIncrease,
    required this.onDecrease,
  });

  final CartProduct product;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Enhancement 1: every cart item reuses the shared detail screen.
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen.fromCartProduct(product),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 78.r,
                child: Image.network(
                  product.thumbnail,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.image_not_supported_outlined),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
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
                    SizedBox(height: 5.h),
                    CustomText(
                      text: '\$${product.price.toStringAsFixed(2)}',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${product.discountPercentage.toStringAsFixed(0)}% off'
                      ' · \$${product.discountedTotal.toStringAsFixed(2)} total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                children: [
                  _QuantityButton(
                    icon: Icons.add,
                    onPressed: onIncrease,
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    child: Text(
                      '${product.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _QuantityButton(
                    icon: Icons.remove,
                    onPressed: onDecrease,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    foregroundColor: colorScheme.onSurface,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 34.r,
      child: IconButton.filled(
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18.sp),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.cart,
    required this.confirming,
    required this.onConfirm,
  });

  final Cart cart;
  final bool confirming;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final savings = cart.total - cart.discountedTotal;
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SummaryRow(label: 'Subtotal', value: cart.total),
              if (savings > 0) _SummaryRow(label: 'Discount', value: -savings),
              const _SummaryRow(label: 'Delivery fee', value: 0),
              Divider(height: 16.h),
              _SummaryRow(
                label: 'Total',
                value: cart.discountedTotal,
                emphasized: true,
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: FilledButton(
                  onPressed: confirming ? null : onConfirm,
                  child: confirming
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirm Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    final sign = value < 0 ? '-' : '';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text('$sign\$${value.abs().toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}

class _CartLoadError extends StatelessWidget {
  const _CartLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 52),
            SizedBox(height: 12.h),
            Text('Unable to load cart.\n$message', textAlign: TextAlign.center),
            SizedBox(height: 12.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
