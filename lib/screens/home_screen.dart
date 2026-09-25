import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../widgets/custom_text.dart';
import 'cart_screen.dart';
import 'product_screen.dart';

const _logoAsset = 'assets/images/bulldogs exchange logo.png';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.username = ''});

  final String username;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Cart? _cart;

  void _updateCart(Cart cart) {
    if (mounted) setState(() => _cart = cart);
  }

  void _openChat() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _ChatSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: _buildTitle(),
          actions: [
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            ProductScreen(cart: _cart, onCartChanged: _updateCart),
            CartScreen(cart: _cart, onCartChanged: _updateCart),
            const _ProfileTab(),
          ],
        ),
        // Enhancement 2: Chat is the FAB and is hidden on CartScreen.
        floatingActionButton: _selectedIndex == 1
            ? null
            : FloatingActionButton(
                tooltip: 'Chat',
                onPressed: _openChat,
                child: const Icon(Icons.chat_bubble_outline),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: NavigationBar(
          height: 70.h,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Home',
            ),
            NavigationDestination(
              icon: _cartIcon(selected: false),
              selectedIcon: _cartIcon(selected: true),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartIcon({required bool selected}) {
    final quantity = _cart?.totalQuantity ?? 0;
    return Badge.count(
      count: quantity,
      isLabelVisible: quantity > 0,
      child: Icon(
        selected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
      ),
    );
  }

  Widget _buildTitle() {
    if (_selectedIndex == 0) {
      return SizedBox(
        width: 54.w,
        height: 46.h,
        child: Image.asset(
          _logoAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.storefront),
        ),
      );
    }
    return CustomText(
      text: _selectedIndex == 1 ? 'Cart' : 'Profile',
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
    );
  }
}

class _ChatSheet extends StatelessWidget {
  const _ChatSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24.w,
        8.h,
        24.w,
        MediaQuery.viewInsetsOf(context).bottom + 24.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_rounded,
            size: 48.sp,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 12.h),
          Text(
            'Chat with Bulldogs Exchange',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 6.h),
          const Text(
            'Ask about a product, your cart, or an order.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          TextField(
            autofocus: true,
            textInputAction: TextInputAction.send,
            decoration: const InputDecoration(
              hintText: 'Type a message',
              prefixIcon: Icon(Icons.message_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150.w,
              height: 132.h,
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Image.asset(
                _logoAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(Icons.storefront, size: 60.sp),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'Bulldogs Exchange customer',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            const Text(
              'Your account details will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
