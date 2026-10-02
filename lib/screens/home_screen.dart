import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'cart_screen.dart';
import 'chat_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';

const _logoAsset = 'assets/images/bulldogs exchange logo.png';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Cart? _cart;

  void _updateCart(Cart cart) {
    if (mounted) setState(() => _cart = cart);
  }

  Future<void> _signOut() async {
    try {
      await UserService().logout();
      if (!mounted) return;
      await Navigator.pushNamedAndRemoveUntil<void>(
        context,
        '/signin',
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not sign out: $error')));
    }
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
            ProductScreen(
              cart: _cart,
              userId: widget.user.id,
              localOnlyCart: widget.user.accessToken.isEmpty,
              onCartChanged: _updateCart,
            ),
            ChatScreen(currentUser: widget.user),
            CartScreen(
              cart: _cart,
              userId: widget.user.id,
              localOnlyCart: widget.user.accessToken.isEmpty,
              onCartChanged: _updateCart,
            ),
            ProfileScreen(user: widget.user, onSignOut: _signOut),
          ],
        ),
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
            const NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
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
    const titles = ['Home', 'Chat', 'Cart', 'Profile'];
    return CustomText(
      text: titles[_selectedIndex],
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
    );
  }
}
