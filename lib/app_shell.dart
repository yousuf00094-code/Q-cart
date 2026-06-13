import 'package:flutter/material.dart';
import 'core/services/locale_service.dart';
import 'core/theme/app_colors.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/categories/presentation/categories_screen.dart';
import 'features/cart/presentation/cart_screen.dart';
import 'features/wishlist/presentation/wishlist_screen.dart';
import 'features/profile/presentation/profile_screen.dart';

class CustomerShell extends StatefulWidget {
  final int initialIndex;
  const CustomerShell({super.key, this.initialIndex = 0});

  static CustomerShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<CustomerShellState>();

  @override
  State<CustomerShell> createState() => CustomerShellState();
}

class CustomerShellState extends State<CustomerShell> {
  late int _index;
  int _cartCount = 0;
  int _wishlistCount = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void switchTab(int index) => setState(() => _index = index);

  void updateCartCount(int count) {
    if (_cartCount != count) setState(() => _cartCount = count);
  }

  void updateWishlistCount(int count) {
    if (_wishlistCount != count) setState(() => _wishlistCount = count);
  }

  static const _screens = [
    HomeScreen(),
    CategoriesScreen(),
    CartScreen(),
    WishlistScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, _, __) => _buildShell(context),
    );
  }

  Widget _buildShell(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEEF0F3), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: LocaleService.t('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_outlined),
            activeIcon: const Icon(Icons.grid_view),
            label: LocaleService.t('categories'),
          ),
          BottomNavigationBarItem(
            icon: _badge(_cartCount, Icons.shopping_cart_outlined),
            activeIcon: _badge(_cartCount, Icons.shopping_cart),
            label: LocaleService.t('cart'),
          ),
          BottomNavigationBarItem(
            icon: _badge(_wishlistCount, Icons.favorite_border),
            activeIcon: _badge(_wishlistCount, Icons.favorite),
            label: LocaleService.t('wishlist'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: LocaleService.t('profile'),
          ),
        ],
        ),
      ),
    );
  }

  Widget _badge(int count, IconData icon) {
    if (count == 0) return Icon(icon);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
