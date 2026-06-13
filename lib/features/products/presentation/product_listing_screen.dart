import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/utils/parse_num.dart';
import '../../../core/utils/category_helpers.dart';
import '../../products/presentation/product_details_screen.dart';

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    this.initialSearch,
  });

  final String? categoryId;
  final String? categoryName;
  final String? initialSearch;

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  List<Map<String, dynamic>> _products = [];
  int _currentPage = 1;
  int _totalPages = 1;

  String _sort = 'newest';
  double _minPrice = 0;
  double _maxPrice = 1000;
  double _pendingMinPrice = 0;
  double _pendingMaxPrice = 1000;
  String _pendingSort = 'newest';

  static const List<String> _sortKeys = [
    'newest',
    'price_asc',
    'price_desc',
    'top_rated',
    'best_seller',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearch ?? '';
    _scrollController.addListener(_onScroll);
    _fetchProducts(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _currentPage < _totalPages) {
        _fetchMoreProducts();
      }
    }
  }

  Future<void> _fetchProducts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _currentPage = 1;
        _products = [];
      });
    }
    try {
      final res = await CustomerService.getProducts(
        page: 1,
        limit: 20,
        categoryId: widget.categoryId,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < 1000 ? _maxPrice : null,
        sort: _sort,
      );
      final rawList = res['data'];
      final data = rawList is List
          ? rawList.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      final meta = res['meta'] as Map<String, dynamic>?;
      final pages = parseInt(meta?['total_pages'], 1);
      if (mounted) {
        setState(() {
          _products = data;
          _currentPage = 1;
          _totalPages = pages;
          _loading = false;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = LocaleService.t('error_generic');
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreProducts() async {
    if (_loadingMore || _currentPage >= _totalPages) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final res = await CustomerService.getProducts(
        page: nextPage,
        limit: 20,
        categoryId: widget.categoryId,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < 1000 ? _maxPrice : null,
        sort: _sort,
      );
      final rawList = res['data'];
      final data = rawList is List
          ? rawList.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      final meta = res['meta'] as Map<String, dynamic>?;
      final pages = parseInt(meta?['total_pages'], _totalPages);
      if (mounted) {
        setState(() {
          _products.addAll(data);
          _currentPage = nextPage;
          _totalPages = pages;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    await _fetchProducts(reset: true);
  }

  void _showFilterSheet(BuildContext context) {
    _pendingSort = _sort;
    _pendingMinPrice = _minPrice;
    _pendingMaxPrice = _maxPrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _FilterSheet(
        initialSort: _pendingSort,
        initialMinPrice: _pendingMinPrice,
        initialMaxPrice: _pendingMaxPrice,
        sortKeys: _sortKeys,
        onApply: (sort, minPrice, maxPrice) {
          setState(() {
            _sort = sort;
            _minPrice = minPrice;
            _maxPrice = maxPrice;
          });
          _fetchProducts(reset: true);
          Navigator.pop(ctx);
        },
        onReset: () {
          setState(() {
            _sort = 'newest';
            _minPrice = 0;
            _maxPrice = 1000;
          });
          _fetchProducts(reset: true);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context),
          body: _buildBody(context),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _fetchProducts(reset: true),
        decoration: InputDecoration(
          hintText: LocaleService.t('search_hint'),
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _showFilterSheet(context),
          icon: const Icon(Icons.tune, color: AppColors.textPrimary),
          tooltip: LocaleService.t('filters'),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.divider,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                LocaleService.t('error_generic'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchProducts(reset: true),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(LocaleService.t('retry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              LocaleService.t('no_products'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.secondary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = _products[index];
                  return _ProductGridCard(
                    product: product,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(
                          productId: product['id']?.toString() ?? '',
                        ),
                      ),
                    ),
                  );
                },
                childCount: _products.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
            ),
          ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.secondary),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initialSort,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.sortKeys,
    required this.onApply,
    required this.onReset,
  });

  final String initialSort;
  final double initialMinPrice;
  final double initialMaxPrice;
  final List<String> sortKeys;
  final void Function(String sort, double minPrice, double maxPrice) onApply;
  final VoidCallback onReset;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _sort;
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    _sort = widget.initialSort;
    _priceRange = RangeValues(widget.initialMinPrice, widget.initialMaxPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleService.t('filters'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            LocaleService.t('sort_by'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sort,
                isExpanded: true,
                dropdownColor: AppColors.background,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                onChanged: (val) {
                  if (val != null) setState(() => _sort = val);
                },
                items: widget.sortKeys
                    .map(
                      (key) => DropdownMenuItem<String>(
                        value: key,
                        child: Text(LocaleService.t(key)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            LocaleService.t('price_range'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${LocaleService.t('qar')} ${_priceRange.start.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${LocaleService.t('qar')} ${_priceRange.end.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000,
            divisions: 100,
            activeColor: AppColors.secondary,
            inactiveColor: AppColors.divider,
            onChanged: (range) => setState(() => _priceRange = range),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onReset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(LocaleService.t('reset')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onApply(
                    _sort,
                    _priceRange.start,
                    _priceRange.end,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(LocaleService.t('apply')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Extract the first image URL from the product's images field.
// API returns images as List<String> (plain URL strings), not List<Map>.
String? _extractImageUrl(Map<String, dynamic> product) {
  final raw = product['images'];
  if (raw is! List || raw.isEmpty) return null;
  final first = raw[0];
  if (first is String && first.isNotEmpty) return first;
  if (first is Map) return first['url']?.toString();
  return null;
}

Widget _gridImageFallback() {
  return SizedBox(
    height: 130,
    width: double.infinity,
    child: productImagePlaceholder(),
  );
}

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({
    required this.product,
    required this.onTap,
  });

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  String _badgeKey() {
    final tags = product['tags'] as List<dynamic>?;
    if (tags != null && tags.contains('best_seller')) return 'best_seller';
    final compareAt = parseDoubleOrNull(product['compare_at_price']);
    final price = parseDouble(product['price']);
    if (compareAt != null && compareAt > price) return 'sale';
    final createdAt = product['created_at'] as String?;
    if (createdAt != null) {
      try {
        final created = DateTime.parse(createdAt);
        if (DateTime.now().difference(created).inDays <= 30) return 'new_label';
      } catch (_) {}
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? '';
    final price = parseDouble(product['price']);
    final compareAt = parseDoubleOrNull(product['compare_at_price']);
    final priceStr = '${LocaleService.t('qar')} ${price.toStringAsFixed(2)}';
    final badgeKey = _badgeKey();
    final imageUrl = _extractImageUrl(product);

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _gridImageFallback(),
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : _gridImageFallback(),
                        )
                      : _gridImageFallback(),
                ),
                if (badgeKey.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeKey == 'sale'
                            ? const Color(0xFFE53935)
                            : badgeKey == 'new_label'
                                ? AppColors.secondary
                                : const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        LocaleService.t(badgeKey),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (compareAt != null && compareAt > price)
                          Text(
                            '${LocaleService.t('qar')} ${compareAt.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
