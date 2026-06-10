import 'package:flutter/material.dart';
import '../../product/presentation/product_details_screen.dart';
import '../../../core/theme/app_colors.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const List<_CategoryItem> _items = [
    _CategoryItem(
      label: 'Groceries',
      icon: Icons.local_grocery_store_outlined,
      color: Color(0xFFD4F5E9),
      count: 128,
    ),
    _CategoryItem(
      label: 'Electronics',
      icon: Icons.devices_outlined,
      color: Color(0xFFDDD9F5),
      count: 64,
    ),
    _CategoryItem(
      label: 'Fashion',
      icon: Icons.checkroom_outlined,
      color: Color(0xFFFFE8D6),
      count: 215,
    ),
    _CategoryItem(
      label: 'Home & Living',
      icon: Icons.home_outlined,
      color: Color(0xFFD6EEFF),
      count: 97,
    ),
    _CategoryItem(
      label: 'Sports',
      icon: Icons.sports_soccer_outlined,
      color: Color(0xFFFFEDD6),
      count: 43,
    ),
    _CategoryItem(
      label: 'Beauty',
      icon: Icons.face_retouching_natural_outlined,
      color: Color(0xFFFFD6E8),
      count: 76,
    ),
    _CategoryItem(
      label: 'Books',
      icon: Icons.menu_book_outlined,
      color: Color(0xFFD6F5FF),
      count: 150,
    ),
    _CategoryItem(
      label: 'Toys',
      icon: Icons.toys_outlined,
      color: Color(0xFFF5F0D6),
      count: 59,
    ),
    _CategoryItem(
      label: 'Automotive',
      icon: Icons.directions_car_outlined,
      color: Color(0xFFE8D6FF),
      count: 32,
    ),
    _CategoryItem(
      label: 'Health',
      icon: Icons.health_and_safety_outlined,
      color: Color(0xFFD6FFE8),
      count: 88,
    ),
    _CategoryItem(
      label: 'Garden',
      icon: Icons.yard_outlined,
      color: Color(0xFFE8FFD6),
      count: 41,
    ),
    _CategoryItem(
      label: 'Pets',
      icon: Icons.pets_outlined,
      color: Color(0xFFFFD6D6),
      count: 55,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Categories',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text(
              '${_items.length} Categories Available',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) =>
                  _CategoryCard(item: _items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.item});

  final _CategoryItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(categoryName: item.label),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: AppColors.secondary, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.count} items',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String label;
  final IconData icon;
  final Color color;
  final int count;

  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
  });
}
