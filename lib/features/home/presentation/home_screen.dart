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
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              LocaleService.isArabic ? 'EN' : 'AR',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.textPrimary,
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      LocaleService.t('limited_offer'),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LocaleService.t('promo_title'),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListingScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        LocaleService.t('shop_now'),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.local_offer_outlined, size: 72, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          GestureDetector(
            onTap: onTap,
            child: Text(
              LocaleService.t('see_all'),
              style: const TextStyle(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesRow(BuildContext context) {
    if (_categoriesLoading) {
      return const SizedBox(
        height: 102,
        child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }
    if (_categoriesError != null) {
      return SizedBox(
        height: 102,
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
    const rowHeight = 252.0;
    if (loading) {
      return const SizedBox(
        height: rowHeight,
        child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }
    if (error != null) {
      return SizedBox(
        height: rowHeight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, size: 32, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(
                LocaleService.t('error_generic'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(LocaleService.t('retry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return SizedBox(
        height: rowHeight,
        child: Center(
          child: Text(LocaleService.t('no_products'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      );
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
              const Icon(Icons.wifi_off_outlined, size: 32, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(
                LocaleService.t('error_generic'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _fetchNewArrivals,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(LocaleService.t('retry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_newArrivals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(LocaleService.t('no_products'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.70,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                    height: 130,
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
