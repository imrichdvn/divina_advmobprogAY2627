import 'dart:convert';

import 'package:divina_advmobprog/models/cart.dart';
import 'package:divina_advmobprog/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('cart screen renders totals and updates item quantity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 715);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 715),
        builder: (context, child) => MaterialApp(
          home: Scaffold(body: CartScreen(cart: cart)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sample product'), findsOneWidget);
    expect(find.text(r'$45.00'), findsOneWidget);
    expect(find.text('Confirm Order'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    expect(find.text(r'$67.50'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('minus removes a cart item after quantity one', (tester) async {
    tester.view.physicalSize = const Size(412, 715);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cart = Cart.fromJson({
      'id': 7,
      'products': [
        {
          'id': 12,
          'title': 'Last product',
          'price': 25,
          'quantity': 1,
          'discountPercentage': 10,
          'thumbnail': 'https://example.com/product.png',
        },
      ],
      'userId': 1,
    });

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 715),
        builder: (context, child) => MaterialApp(
          home: Scaffold(body: CartScreen(cart: cart)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(find.text('Last product'), findsNothing);
    expect(find.text('This cart is empty.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new demo user starts with an empty local cart', (tester) async {
    tester.view.physicalSize = const Size(412, 715);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 715),
        builder: (context, child) => const MaterialApp(
          home: Scaffold(body: CartScreen(userId: 209, localOnlyCart: true)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('This cart is empty.'), findsOneWidget);
    expect(find.textContaining('Failed to load cart'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local cart screen restores saved items after sign-in', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 715);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final savedCart = Cart.fromJson({
      'id': 0,
      'userId': 209,
      'products': [
        {
          'id': 42,
          'title': 'Restored demo product',
          'price': 30,
          'quantity': 2,
          'discountPercentage': 10,
          'thumbnail': '',
        },
      ],
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'local_cart_209',
      jsonEncode(savedCart.toJson()),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(412, 715),
        builder: (context, child) => const MaterialApp(
          home: Scaffold(body: CartScreen(userId: 209, localOnlyCart: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Restored demo product'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
