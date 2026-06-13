import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

IconData categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('electron') || n.contains('tech') || n.contains('phone') ||
      n.contains('computer') || n.contains('gadget') || n.contains('device')) {
    return Icons.devices_outlined;
  }
  if (n.contains('cloth') || n.contains('fashion') || n.contains('apparel') ||
      n.contains('wear') || n.contains('dress') || n.contains('shirt')) {
    return Icons.checkroom_outlined;
  }
  if (n.contains('food') || n.contains('grocer') || n.contains('supermarket') ||
      n.contains('fruit') || n.contains('vegetable') || n.contains('fresh')) {
    return Icons.local_grocery_store_outlined;
  }
  if (n.contains('beauty') || n.contains('care') || n.contains('cosmetic') ||
      n.contains('personal') || n.contains('skin') || n.contains('makeup')) {
    return Icons.face_retouching_natural;
  }
  if (n.contains('home') || n.contains('kitchen') || n.contains('furniture') ||
      n.contains('decor') || n.contains('appliance') || n.contains('household')) {
    return Icons.kitchen_outlined;
  }
  if (n.contains('sport') || n.contains('fitness') || n.contains('gym') ||
      n.contains('outdoor') || n.contains('exercise')) {
    return Icons.fitness_center_outlined;
  }
  if (n.contains('toy') || n.contains('game') || n.contains('kids') || n.contains('baby')) {
    return Icons.toys_outlined;
  }
  if (n.contains('book') || n.contains('stationery') || n.contains('office')) {
    return Icons.menu_book_outlined;
  }
  if (n.contains('health') || n.contains('medical') || n.contains('pharma') ||
      n.contains('wellness')) {
    return Icons.local_pharmacy_outlined;
  }
  if (n.contains('auto') || n.contains('car') || n.contains('vehicle') || n.contains('motor')) {
    return Icons.directions_car_outlined;
  }
  return Icons.category_outlined;
}

Color categoryIconColor(String name) {
  final n = name.toLowerCase();
  if (n.contains('electron') || n.contains('tech') || n.contains('phone') || n.contains('computer')) return const Color(0xFF2563EB);
  if (n.contains('cloth') || n.contains('fashion') || n.contains('apparel')) return const Color(0xFFDB2777);
  if (n.contains('food') || n.contains('grocer') || n.contains('fresh')) return const Color(0xFF059669);
  if (n.contains('beauty') || n.contains('care') || n.contains('cosmetic')) return const Color(0xFF7C3AED);
  if (n.contains('home') || n.contains('kitchen') || n.contains('furniture')) return const Color(0xFFD97706);
  if (n.contains('sport') || n.contains('fitness')) return const Color(0xFFDC2626);
  if (n.contains('toy') || n.contains('kids')) return const Color(0xFFEA580C);
  if (n.contains('book') || n.contains('stationery')) return const Color(0xFF4F46E5);
  if (n.contains('health') || n.contains('pharma')) return const Color(0xFF0D9488);
  return AppColors.secondary;
}

Color categoryBgColor(String name) {
  final n = name.toLowerCase();
  if (n.contains('electron') || n.contains('tech') || n.contains('phone') || n.contains('computer')) return const Color(0xFFEFF6FF);
  if (n.contains('cloth') || n.contains('fashion') || n.contains('apparel')) return const Color(0xFFFCE7F3);
  if (n.contains('food') || n.contains('grocer') || n.contains('fresh')) return const Color(0xFFECFDF5);
  if (n.contains('beauty') || n.contains('care') || n.contains('cosmetic')) return const Color(0xFFF5F3FF);
  if (n.contains('home') || n.contains('kitchen') || n.contains('furniture')) return const Color(0xFFFFFBEB);
  if (n.contains('sport') || n.contains('fitness')) return const Color(0xFFFEF2F2);
  if (n.contains('toy') || n.contains('kids')) return const Color(0xFFFFF7ED);
  if (n.contains('book') || n.contains('stationery')) return const Color(0xFFEEF2FF);
  if (n.contains('health') || n.contains('pharma')) return const Color(0xFFF0FDFA);
  return const Color(0xFFF0FDF4);
}

Widget productImagePlaceholder() {
  return Container(
    color: const Color(0xFFF8FAFC),
    child: const Center(
      child: Icon(Icons.shopping_bag_outlined, size: 40, color: Color(0xFFCBD5E1)),
    ),
  );
}
