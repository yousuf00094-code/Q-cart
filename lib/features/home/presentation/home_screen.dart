import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/utils/parse_num.dart';
import '../../../core/utils/category_helpers.dart';
import '../../products/presentation/product_details_screen.dart';
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
  bool _featuredLoading = true;
  bool _bestSellingLoading = true;
  bool _newArrivalsLoading = true;
  String? _categoriesError;
  String? _featuredError;
  String? _bestSellingError;
  String? _newArrivalsError;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _featured = [];
  List<Map<String, dynamic>> _bestSelling = [];
  List<Map<String, dynamic>> _newArrivals = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchFeatured();
    _fetchBestSelling();
    _fetchNewArrivals();
  }

  Future<void> _fetchCategories() async {
    setState(() { _categoriesLoading = true; _categoriesError = null; });
    try {
      final data = await CustomerService.getCategories();
      if (mounted) setState(() { _categories = data; _categoriesLoading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _categoriesError = e.message; _categoriesLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _categoriesError = LocaleService.t('error_generic'); _categoriesLoading = false; });
    }
  }

  Future<void> _fetchFeatured() async {
    setState(() { _featuredLoading = true; _featuredError = null; });
    try {
      debugPrint('[Home] fetchFeatured: starting');
      final res = await CustomerService.getProducts(featured: true, limit: 6);
      final raw = res['data'];
      final data = _parseProductList(raw);
      debugPrint('[Home] fetchFeatured: got ${data.length} products');
      if (mounted) setState(() { _featured = data; _featuredLoading = false; });
    } on ApiException catch (e) {
      debugPrint('[Home] fetchFeatured: ApiException ${e.statusCode} ${e.message}');
      if (mounted) setState(() { _featuredError = e.message; _featuredLoading = false; });
    } catch (e, st) {
      debugPrint('[Home] fetchFeatured: error $e\n$st');
      if (mounted) setState(() { _featuredError = LocaleService.t('error_generic'); _featuredLoading = false; });
    }
  }

  Future<void> _fetchBestSelling() async {
    setState(() { _bestSellingLoading = true; _bestSellingError = null; });
    try {
      debugPrint('[Home] fetchBestSelling: starting');
      final res = await CustomerService.getProducts(sort: 'best_seller', limit: 6);
      final raw = res['data'];
      final data = _parseProductList(raw);
      debugPrint('[Home] fetchBestSelling: got ${data.length} products');
      if (mounted) setState(() { _bestSelling = data; _bestSellingLoading = false; });
    } on ApiException catch (e) {
      debugPrint('[Home] fetchBestSelling: ApiException ${e.statusCode} ${e.message}');
      if (mounted) setState(() { _bestSellingError = e.message; _bestSellingLoading = false; });
    } catch (e, st) {
      debugPrint('[Home] fetchBestSelling: error $e\n$st');
      if (mounted) setState(() { _bestSellingError = LocaleService.t('error_generic'); _bestSellingLoading = false; });
    }
  }

  Future<void> _fetchNewArrivals() async {
    setState(() { _newArrivalsLoading = true; _newArrivalsError = null; });
    try {
      debugPrint('[Home] fetchNewArrivals: starting');
      final res = await CustomerService.getProducts(sort: 'newest', limit: 8);
      final raw = res['data'];
      final data = _parseProductList(raw);
      debugPrint('[Home] fetchNewArrivals: got ${data.length} products');
      if (mounted) setState(() { _newArrivals = data; _newArrivalsLoading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _newArrivalsError = e.message; _newArrivalsLoading = false; });
    } catch (e, st) {
      debugPrint('[Home] fetchNewArrivals: error $e\n$st');
      if (mounted) setState(() { _newArrivalsError = LocaleService.t('error_generic'); _newArrivalsLoading = false; });
    }
  }

  List<Map<String, dynamic>> _parseProductList(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];
    final result = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        result.add(item);
      } else if (item is Map) {
        result.add(Map<String, dynamic>.from(item));
      }
    }
    return result;
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _fetchCategories(),
      _fetchFeatured(),
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
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProductListingScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildProductRow(
                    context,
                    items: _bestSelling,
                    loading: _bestSellingLoading,
                    error: _bestSellingError,
                    onRetry: _fetchBestSelling,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    LocaleService.t('featured_products'),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProductListingScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildProductRow(
                    context,
                    items: _featured,
                    loading: _featuredLoading,
                    error: _featuredError,
                    onRetry: _fetchFeatured,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    LocaleService.t('new_arrivals'),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProductListingScreen())),
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.secondary),
            ),
            TextSpan(
              text: ' Cart',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: LocaleService.toggle,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              LocaleService.isArabic ? 'EN' : 'AR',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary),
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
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
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListingScreen())),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 10),
              Text(
                LocaleService.t('search_hint'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListingScreen())),
        child: Container(
          width: double.infinity,
          height: 170,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3D3A6B), Color(0xFF5A56A0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Positioned(
                right: -35,
                top: -35,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                right: 55,
                bottom: -28,
                child: Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              LocaleService.t('limited_offer'),
                              style: const TextStyle(
                                color: Color(0xFF1C1A2E),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LocaleService.t('promo_title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  LocaleService.t('shop_now'),
                                  style: const TextStyle(
                                    color: Color(0xFF4D4A7D),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF4D4A7D)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.13),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'UP TO',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '20%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'OFF',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LocaleService.t('see_all'),
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.secondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow(BuildContext context) {
    if (_categoriesLoading) {
      return _buildCategoriesSkeleton();
    }
    if (_categoriesError != null) {
      return _buildCategoriesSkeleton(showRetry: true, onRetry: _fetchCategories);
    }
    final displayCategories = _categories.take(8).toList();
    return SizedBox(
      height: 102,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: displayCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final cat = displayCategories[index];
          final name = cat['name']?.toString() ?? '';
          final imageUrl = cat['image_url']?.toString();
          final icon = categoryIcon(name);
          final iconColor = categoryIconColor(name);
          final bgColor = categoryBgColor(name);
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductListingScreen(
                  categoryId: cat['id']?.toString(),
                  categoryName: name,
                ),
              ),
            ),
            child: SizedBox(
              width: 72,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(icon, color: iconColor, size: 28),
                            ),
                          )
                        : Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductRow(
    BuildContext context, {
    required List<Map<String, dynamic>> items,
    required bool loading,
    required String? error,
    required VoidCallback onRetry,
  }) {
    const rowHeight = 265.0;
    if (loading) {
      return _buildProductRowSkeleton(rowHeight);
    }
    if (error != null) {
      return _buildProductRowSkeleton(rowHeight, showRetry: true, onRetry: onRetry);
    }
    if (items.isEmpty) {
      return _buildProductRowSkeleton(rowHeight);
    }
    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _ProductCard(
          product: items[index],
          fixedWidth: 168,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(productId: items[index]['id']?.toString() ?? ''),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewArrivalsGrid(BuildContext context) {
    if (_newArrivalsLoading) {
      return _buildGridSkeleton();
    }
    if (_newArrivalsError != null) {
      return _buildGridSkeleton(showRetry: true, onRetry: _fetchNewArrivals);
    }
    if (_newArrivals.isEmpty) {
      return _buildGridSkeleton();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.66,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: _newArrivals.length,
        itemBuilder: (context, index) => _ProductCard(
          product: _newArrivals[index],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(productId: _newArrivals[index]['id']?.toString() ?? ''),
            ),
          ),
        ),
      ),
    );
  }

  // ── Skeleton helpers ─────────────────────────────────────────────────────────

  Widget _skeletonBox({double? w, required double h, double radius = 8}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF0F3),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildCategoriesSkeleton({bool showRetry = false, VoidCallback? onRetry}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 102,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _skeletonBox(w: 64, h: 64, radius: 18),
                const SizedBox(height: 6),
                _skeletonBox(w: 44, h: 10, radius: 5),
              ],
            ),
          ),
        ),
        if (showRetry)
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(LocaleService.t('retry'), style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductRowSkeleton(double rowHeight, {bool showRetry = false, VoidCallback? onRetry}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: rowHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Container(
              width: 168,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBox(h: 150, radius: 0),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _skeletonBox(w: double.infinity, h: 12),
                        const SizedBox(height: 6),
                        _skeletonBox(w: 100, h: 12),
                        const SizedBox(height: 14),
                        _skeletonBox(w: 70, h: 14, radius: 7),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showRetry)
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(LocaleService.t('retry'), style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGridSkeleton({bool showRetry = false, VoidCallback? onRetry}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.66,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _skeletonBox(h: double.infinity, radius: 0),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _skeletonBox(w: double.infinity, h: 12),
                          const SizedBox(height: 6),
                          _skeletonBox(w: 80, h: 12),
                          const Spacer(),
                          _skeletonBox(w: 60, h: 14, radius: 7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showRetry)
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(LocaleService.t('retry'), style: const TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Category icon/colour helpers are in lib/core/utils/category_helpers.dart

// ── Product image extraction ─────────────────────────────────────────────────

String? _extractImageUrl(Map<String, dynamic> product) {
  final raw = product['images'];
  if (raw is! List || raw.isEmpty) return null;
  final first = raw[0];
  if (first is String && first.isNotEmpty) return first;
  if (first is Map) return first['url']?.toString();
  return null;
}

// ── Product card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap, this.fixedWidth});

  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final double? fixedWidth;

  @override
  Widget build(BuildContext context) {
    try {
      return _buildCard(context);
    } catch (e) {
      debugPrint('[ProductCard] build error: $e');
      return _errorCard();
    }
  }

  Widget _buildCard(BuildContext context) {
    final name        = product['name']?.toString() ?? '';
    final price       = parseDouble(product['price']);
    final rating      = parseDouble(product['average_rating']);
    final reviewCount = parseInt(product['review_count']);
    final priceStr    = '${LocaleService.t('qar')} ${price.toStringAsFixed(2)}';
    final imageUrl    = _extractImageUrl(product);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fixedWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                                progress == null ? child : _placeholder(),
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.favorite_border, size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            // ── Info ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 3),
                      Text(
                        rating > 0 ? rating.toStringAsFixed(1) : '—',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      if (reviewCount > 0) ...[
                        const SizedBox(width: 3),
                        Text(
                          '($reviewCount)',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price + Add
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          priceStr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 17),
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

  Widget _errorCard() {
    return Container(
      width: fixedWidth,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Center(
        child: Icon(Icons.error_outline, color: AppColors.textSecondary, size: 32),
      ),
    );
  }

  Widget _placeholder() => productImagePlaceholder();
}
