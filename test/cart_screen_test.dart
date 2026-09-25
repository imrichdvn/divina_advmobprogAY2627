import 'package:divina_advmobprog/models/cart.dart';
import 'package:divina_advmobprog/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
