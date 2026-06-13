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
  int _cartCount    = 0;
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
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final items = [
      _NavItem(Icons.home_rounded,          Icons.home_outlined,            LocaleService.t('home')),
      _NavItem(Icons.grid_view_rounded,     Icons.grid_view_outlined,       LocaleService.t('categories')),
      _NavItem(Icons.shopping_bag_rounded,  Icons.shopping_bag_outlined,   LocaleService.t('cart'),     badge: _cartCount),
      _NavItem(Icons.favorite_rounded,      Icons.favorite_outline,         LocaleService.t('wishlist'), badge: _wishlistCount),
      _NavItem(Icons.person_rounded,        Icons.person_outline,           LocaleService.t('profile')),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8E8E8), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(items.length, (i) {
              final item   = items[i];
              final active = _index == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _index = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            active ? item.activeIcon : item.icon,
                            size: 24,
                            color: active
                                ? AppColors.primary
                                : const Color(0xFFBBBBBB),
                          ),
                          if (item.badge > 0)
                            Positioned(
                              right: -9, top: -5,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE5002B),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
                                child: Text(
                                  item.badge > 99 ? '99+' : '${item.badge}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 9,
                                      fontWeight: FontWeight.w800),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active
                              ? AppColors.primary
                              : const Color(0xFFBBBBBB),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  final int badge;
  const _NavItem(this.activeIcon, this.icon, this.label, {this.badge = 0});
}
