import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary   = Color(0xFF3B2E9E); // Deep brand purple
  static const Color secondary = Color(0xFF3B2E9E); // Alias
  static const Color accent    = Color(0xFFFF6B00); // Orange CTA

  // Page / card backgrounds
  static const Color background = Color(0xFFF5F6F7);
  static const Color surface    = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF767676);

  // UI chrome
  static const Color divider   = Color(0xFFEBEBEB);

  // E-commerce specific
  static const Color priceRed  = Color(0xFFB12704); // price / savings
  static const Color flashRed  = Color(0xFFE8192C); // flash deals
  static const Color ratingGold = Color(0xFFFFA41C); // stars
  static const Color stockGreen = Color(0xFF007600); // "In Stock"
}
