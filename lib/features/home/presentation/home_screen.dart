import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/locale_service.dart';
import '../../product/presentation/product_details_screen.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../products/presentation/product_listing_screen.dart';
import '../../../app_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _categoriesLoading = true;
  bool _bestSellingLoading = true;
  bool _newArrivalsLoading = true;
  String? _categoriesError;
  String? _bestSellingError;
  String? _newArrivalsError;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _bestSelling = [];
  List<Map<String, dynamic>> _newArrivals = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchBestSelling();
    _fetchNewArrivals();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });
    try {
      final data = await CustomerService.getCategories();
      if (mounted) {
        setState(() {
          _categories = data;
          _categoriesLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _categoriesError = e.message;
          _categoriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoriesError = LocaleService.t('error_generic');
          _categoriesLoading = false;
        });
      }
    }
  }

  Future<void> _fetchBestSelling() async {
    setState(() {
      _bestSellingLoading = true;
      _bestSellingError = null;
    });
    try {
      final res = await CustomerService.getProducts(sort: 'best_seller', limit: 6);
      final data = (res['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _bestSelling = data;
          _bestSellingLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _bestSellingError = e.message;
          _bestSellingLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bestSellingError = LocaleService.t('error_generic');
          _bestSellingLoading = false;
        });
      }
    }
  }

  Future<void> _fetchNewArrivals() async {
    setState(() {
      _newArrivalsLoading = true;
      _newArrivalsError = null;
    });
    try {
      final res = await CustomerService.getProducts(sort: 'newest', limit: 8);
      final data = (res['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _newArrivals = data;
          _newArrivalsLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _newArrivalsError = e.message;
          _newArrivalsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _newArrivalsError = LocaleService.t('error_generic');
          _newArrivalsLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _fetchCategories(),
      _fetchBestSelling(),
      _fetchNewArrivals(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.secondary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildSearchBar(context),
                  const SizedBox(height: 20),
                  _buildPromoBanner(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    LocaleService.t('categories'),
                    onTap: () => CustomerShell.of(context)?.switchTab(1),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoriesRow(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    LocaleService.t('best_selling'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductListingScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBestSellingRow(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    LocaleService.t('new_arrivals'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductListingScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNewArrivalsGrid(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Q',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
            TextSpan(
              text: ' Cart',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => LocaleService.toggle(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              LocaleService.isArabic ? 'EN' : 'AR',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.textPrimary,
        ),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
          icon: const Icon(Icons.shopping_cart_outlined),
          color: AppColors.textPrimary,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductListingScreen()),
        ),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 10),
              Text(
                LocaleService.t('search_hint'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.secondary, Color(0xFF6D69A8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      LocaleService.t('limited_offer'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LocaleService.t('promo_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductListingScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        LocaleService.t('shop_now'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.local_offer_outlined,
              size: 72,
              color: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              LocaleService.t('see_all'),
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow(BuildContext context) {
    if (_categoriesLoading) {
      return const SizedBox(
        height: 88,
        child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }
    if (_categoriesError != null) {
      return SizedBox(
        height: 88,
        child: Center(
          child: TextButton.icon(
            onPressed: _fetchCategories,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(LocaleService.t('retry')),
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
          ),
        ),
      );
    }
    final displayCategories = _categories.take(8).toList();
    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: displayCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = displayCategories[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductListingScreen(
                  categoryId: cat['id']?.toString(),
                  categoryName: cat['name']?.toString(),
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                    color: AppColors.secondary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 56,
                  child: Text(
                    cat['name']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBestSellingRow(BuildContext context) {
    if (_bestSellingLoading) {
      return const SizedBox(
        height: 210,
        child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }
    if (_bestSellingError != null) {
      return SizedBox(
        height: 210,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _bestSellingError!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _fetchBestSelling,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(LocaleService.t('retry')),
                style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
              ),
            ],
          ),
        ),
      );
    }
    if (_bestSelling.isEmpty) {
      return SizedBox(
        height: 210,
        child: Center(
          child: Text(
            LocaleService.t('no_products'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }
    return SizedBox(
      height: 210,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _bestSelling.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _ProductCard(
          product: _bestSelling[index],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(
                productId: _bestSelling[index]['id']?.toString(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewArrivalsGrid(BuildContext context) {
    if (_newArrivalsLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }
    if (_newArrivalsError != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _newArrivalsError!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _fetchNewArrivals,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(LocaleService.t('retry')),
                style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
              ),
            ],
          ),
        ),
      );
    }
    if (_newArrivals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          LocaleService.t('no_products'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: _newArrivals.length,
        itemBuilder: (context, index) => _ProductCard(
          product: _newArrivals[index],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(
                productId: _newArrivals[index]['id']?.toString(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
  });

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final priceStr = '${LocaleService.t('qar')} ${price.toStringAsFixed(2)}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4F5E9), AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shopping_basket_outlined,
                      size: 44,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priceStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
