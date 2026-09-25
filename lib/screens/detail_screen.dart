import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../widgets/custom_text.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.price,
    required this.thumbnail,
    required this.description,
    this.category = '',
    this.discountPercentage = 0,
    this.rating,
  });

  factory DetailScreen.fromProduct(Product product) {
    return DetailScreen(
      id: product.id,
      title: product.title,
      price: product.price,
      thumbnail: product.thumbnail,
      description: product.description,
      category: product.category,
      discountPercentage: product.discountPercentage,
      rating: product.rating,
    );
  }

  factory DetailScreen.fromCartProduct(CartProduct product) {
    return DetailScreen(
      id: product.id,
      title: product.title,
      price: product.price,
      thumbnail: product.thumbnail,
      description:
          'This product was loaded from the selected user cart. '
          'Open it from Products to see the complete catalog description.',
      discountPercentage: product.discountPercentage,
    );
  }

  final int id;
  final String title;
  final double price;
  final String thumbnail;
  final String description;
  final String category;
  final double discountPercentage;
  final double? rating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300.h,
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Image.network(
                thumbnail,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.image_not_supported_outlined, size: 72),
              ),
            ),
            SizedBox(height: 20.h),
            if (category.isNotEmpty)
              Text(
                category.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.1,
                ),
              ),
            SizedBox(height: 6.h),
            CustomText(
              text: title,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                CustomText(
                  text: '\$${price.toStringAsFixed(2)}',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
                if (discountPercentage > 0) ...[
                  SizedBox(width: 10.w),
                  Chip(
                    label: Text(
                      '${discountPercentage.toStringAsFixed(0)}% off',
                    ),
                  ),
                ],
                const Spacer(),
                if (rating != null) ...[
                  const Icon(Icons.star_rounded, color: Colors.amber),
                  Text(rating!.toStringAsFixed(1)),
                ],
              ],
            ),
            SizedBox(height: 18.h),
            CustomText(text: description, fontSize: 14.sp),
          ],
        ),
      ),
    );
  }
}
