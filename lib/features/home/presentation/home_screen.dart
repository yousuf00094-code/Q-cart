import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/api_client.dart';
import '../../products/presentation/product_details_screen.dart';
import '../../products/presentation/product_listing_screen.dart';
import '../../cart/presentation/cart_screen.dart';

// ── Category icon map (monochrome — no per-category colours) ─────────────────
const _kCatIcons = <String, IconData>{
  'cat_1':  Icons.phone_android,
  'cat_2':  Icons.dry_cleaning,
  'cat_3':  Icons.weekend,
  'cat_4':  Icons.spa,
  'cat_5':  Icons.fitness_center,
  'cat_6':  Icons.local_grocery_store,
  'cat_7':  Icons.menu_book,
  'cat_8':  Icons.sports_esports,
  'cat_9':  Icons.directions_car,
  'cat_10': Icons.local_hospital,
  'cat_11': Icons.diamond,
  'cat_12': Icons.child_friendly,
};

// ── HomeScreen ────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _categories  = [];
  List<Map<String, dynamic>> _bestSelling = [];
  List<Map<String, dynamic>> _featured    = [];
  List<Map<String, dynamic>> _newArrivals = [];
  List<Map<String, dynamic>> _flashDeals  = [];
  bool _loading = true;

  Duration _flashLeft = const Duration(hours: 1, minutes: 58, seconds: 22);
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _flashTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_flashLeft.inSeconds > 0) _flashLeft -= const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  static List<Map<String, dynamic>> _parseProducts(Map<String, dynamic> res) {
    final raw = res['data'];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _loadAll() async {
    try {
      final cats  = await CustomerService.getCategories();
      final bs    = await CustomerService.getProducts(sort: 'sold_desc',  limit: 10);
      final feat  = await CustomerService.getProducts(featured: true,      limit: 10);
      final newA  = await CustomerService.getProducts(sort: 'newest',      limit: 10);
      final flash = await CustomerService.getProducts(flashDeals: true,    limit: 8);
      if (!mounted) return;
      setState(() {
        _categories  = cats;
        _bestSelling = _parseProducts(bs);
        _featured    = _parseProducts(feat);
        _newArrivals = _parseProducts(newA);
        _flashDeals  = _parseProducts(flash);
        _loading     = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _push(Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  void _openProduct(Map<String, dynamic> p) =>
      _push(ProductDetailsScreen(productId: p['id'] as String));

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── App bar (white, no colour fills) ──────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 52,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          // Logo mark
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: const Text('Q',
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w900, height: 1)),
          ),
          const SizedBox(width: 8),
          const Text('Q Cart',
              style: TextStyle(color: Color(0xFF111111), fontSize: 18,
                  fontWeight: FontWeight.w700, letterSpacing: -0.3)),
          const Spacer(),
          _iconBtn(Icons.notifications_outlined, () {}),
          _iconBtn(Icons.shopping_bag_outlined, () => _push(const CartScreen())),
        ]),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(57),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 1, color: const Color(0xFFEEEEEE)),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => IconButton(
    icon: Icon(icon, color: const Color(0xFF333333), size: 22),
    onPressed: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
  );

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: GestureDetector(
        onTap: () => _push(const ProductListingScreen()),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFE2E2E2)),
          ),
          child: Row(children: [
            const SizedBox(width: 11),
            const Icon(Icons.search, size: 18, color: Color(0xFF999999)),
            const SizedBox(width: 7),
            const Expanded(
              child: Text('Search products, brands...',
                  style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
            ),
            Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Text('Search',
                  style: TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(),
        const SizedBox(height: 8),
        _buildPerks(),
        const SizedBox(height: 8),
        _buildCategories(),
        const SizedBox(height: 8),
        _buildFlashDeals(),
        const SizedBox(height: 8),
        _buildSection(
          title: 'Best Sellers',
          items: _bestSelling,
          onSeeAll: () => _push(const ProductListingScreen(
              title: 'Best Sellers', sort: 'sold_desc')),
        ),
        const SizedBox(height: 8),
        _buildSection(
          title: 'New Arrivals',
          items: _newArrivals,
          onSeeAll: () => _push(const ProductListingScreen(
              title: 'New Arrivals', sort: 'newest')),
        ),
        const SizedBox(height: 8),
        _buildSection(
          title: 'Recommended For You',
          items: _featured,
          onSeeAll: () => _push(const ProductListingScreen(
              title: 'Recommended For You', featured: true)),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Hero banner (single, white, clean) ────────────────────────────────────

  Widget _buildHero() {
    final img = (!_loading && _bestSelling.isNotEmpty)
        ? _imgUrl(_bestSelling.first)
        : null;

    return GestureDetector(
      onTap: () => _push(const ProductListingScreen(
          title: 'Best Sellers', sort: 'sold_desc')),
      child: Container(
        height: 188,
        color: Colors.white,
        child: Row(children: [
          // Left — text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEBF9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text('NEW SEASON',
                        style: TextStyle(color: AppColors.primary, fontSize: 9.5,
                            fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  ),
                  const SizedBox(height: 10),
                  const Text('Premium\nCollection',
                      style: TextStyle(color: Color(0xFF111111), fontSize: 24,
                          fontWeight: FontWeight.w800, height: 1.15,
                          letterSpacing: -0.4)),
                  const SizedBox(height: 6),
                  const Text('Curated for Qatar',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 12.5)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text('Shop Now',
                        style: TextStyle(color: Colors.white, fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          // Right — image
          Container(
            width: 165,
            height: 188,
            color: const Color(0xFFF8F8F8),
            child: img != null
                ? Image.network(img,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox())
                : const SizedBox(),
          ),
        ]),
      ),
    );
  }

  String? _imgUrl(Map<String, dynamic> p) {
    final raw = p['images'];
    if (raw is List && raw.isNotEmpty) {
      final f = raw[0];
      if (f is String && f.isNotEmpty) return f;
      if (f is Map) return f['url']?.toString();
    }
    return null;
  }

  // ── Perks strip ───────────────────────────────────────────────────────────

  Widget _buildPerks() {
    final items = [
      (Icons.local_shipping_outlined, 'Free Delivery', 'On QAR 99+'),
      (Icons.replay_outlined,         '30-Day Return',  'Hassle free'),
      (Icons.lock_outline,            'Secure Pay',     '100% safe'),
      (Icons.verified_outlined,       'Authentic',      'Original brands'),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: List.generate(items.length * 2 - 1, (idx) {
          if (idx.isOdd) {
            return Container(
                width: 1, height: 30, color: const Color(0xFFEEEEEE));
          }
          final p = items[idx ~/ 2];
          return Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(p.$1, size: 20, color: AppColors.primary),
              const SizedBox(height: 5),
              Text(p.$2,
                  style: const TextStyle(fontSize: 10.5,
                      fontWeight: FontWeight.w600, color: Color(0xFF222222))),
              Text(p.$3,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF999999))),
            ]),
          );
        }),
      ),
    );
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Widget _buildCategories() {
    final cats = _loading
        ? List.generate(10, (i) => {'id': 'cat_${i + 1}', 'name': ''})
        : _categories;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            const Text('Categories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: Color(0xFF111111))),
            const Spacer(),
            GestureDetector(
              onTap: () => _push(const ProductListingScreen()),
              child: const Text('See All',
                  style: TextStyle(fontSize: 13, color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        SizedBox(
          height: 86,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: cats.length,
            itemBuilder: (_, i) {
              final cat   = cats[i];
              final catId = cat['id'] as String? ?? 'cat_${i + 1}';
              final name  = cat['name'] as String? ?? '';
              if (_loading) return _skCatItem();
              final icon = _kCatIcons[catId] ?? Icons.category;
              return GestureDetector(
                onTap: () => _push(ProductListingScreen(
                    title: name, categoryId: catId)),
                child: SizedBox(
                  width: 70,
                  child: Column(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF3F3F3),
                        border: Border.all(color: const Color(0xFFE6E6E6)),
                      ),
                      child: Icon(icon, size: 23,
                          color: const Color(0xFF444444)),
                    ),
                    const SizedBox(height: 6),
                    Text(name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF444444), height: 1.2)),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ── Flash Deals ───────────────────────────────────────────────────────────

  Widget _buildFlashDeals() {
    final h  = _flashLeft.inHours;
    final m  = _flashLeft.inMinutes % 60;
    final s  = _flashLeft.inSeconds % 60;
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');

    return Container(
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          color: const Color(0xFF111111),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            const Text('Flash Deals',
                style: TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            _timerBox(hh), _timerColon(),
            _timerBox(mm), _timerColon(),
            _timerBox(ss),
            const Spacer(),
            GestureDetector(
              onTap: () => _push(const ProductListingScreen(
                  title: 'Flash Deals')),
              child: const Text('See All',
                  style: TextStyle(color: Colors.white54, fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
        SizedBox(
          height: 252,
          child: _loading
              ? _skProductRow(compact: true)
              : _flashDeals.isEmpty
                  ? _emptyHint()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      itemCount: _flashDeals.length,
                      itemBuilder: (_, i) => _ProductCard(
                        product: _flashDeals[i],
                        compact: true,
                        onTap: () => _openProduct(_flashDeals[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _timerBox(String v) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: Text(v,
        style: const TextStyle(color: Colors.white, fontSize: 12,
            fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  );

  Widget _timerColon() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 3),
    child: Text(':',
        style: TextStyle(color: Colors.white54, fontSize: 13,
            fontWeight: FontWeight.w700)),
  );

  // ── Generic product section ───────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> items,
    required VoidCallback onSeeAll,
  }) {
    return Container(
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: Color(0xFF111111))),
            const Spacer(),
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('See All',
                  style: TextStyle(fontSize: 13, color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        SizedBox(
          height: 268,
          child: _loading
              ? _skProductRow()
              : items.isEmpty
                  ? _emptyHint()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _ProductCard(
                        product: items[i],
                        onTap: () => _openProduct(items[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  // ── Skeleton loaders ──────────────────────────────────────────────────────

  Widget _skBox(double w, double h, {double r = 6}) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(r)),
  );

  Widget _skCatItem() => SizedBox(
    width: 70,
    child: Column(children: [
      Container(width: 52, height: 52,
          decoration: const BoxDecoration(
              color: Color(0xFFEEEEEE), shape: BoxShape.circle)),
      const SizedBox(height: 6),
      _skBox(38, 9),
    ]),
  );

  Widget _skProductRow({bool compact = false}) {
    final w = compact ? 155.0 : 175.0;
    final h = compact ? 118.0 : 138.0;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        width: w,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _skBox(w, h, r: 10),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _skBox(w - 20, 11),
              const SizedBox(height: 5),
              _skBox((w - 20) * 0.65, 11),
              const SizedBox(height: 8),
              _skBox(50, 10),
              const SizedBox(height: 8),
              _skBox(65, 14),
              const SizedBox(height: 10),
              _skBox(w - 20, 32, r: 7),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _emptyHint() => const Center(
    child: Text('No products available',
        style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
  );
}

// ── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    this.compact = false,
  });
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _busy   = false;
  bool _wished = false;

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  String? _imageUrl() {
    final raw = widget.product['images'];
    if (raw is List && raw.isNotEmpty) {
      final f = raw[0];
      if (f is String && f.isNotEmpty) return f;
      if (f is Map) return f['url']?.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p         = widget.product;
    final name      = p['name'] as String? ?? '';
    final price     = (p['price'] as num?)?.toDouble() ?? 0.0;
    final compareAt = (p['compare_at_price'] as num?)?.toDouble();
    final rating    = (p['average_rating'] as num?)?.toDouble() ?? 0.0;
    final reviews   = p['review_count'] as int? ?? 0;
    final imgUrl    = _imageUrl();
    final discount  = (compareAt != null && compareAt > price)
        ? ((1 - price / compareAt) * 100).round()
        : 0;

    final cardW = widget.compact ? 155.0 : 175.0;
    final imgH  = widget.compact ? 120.0 : 140.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: cardW,
        margin: const EdgeInsets.only(right: 10, bottom: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────────
            Stack(children: [
              SizedBox(
                width: double.infinity,
                height: imgH,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10)),
                  child: imgUrl != null
                      ? Image.network(imgUrl,
                          width: double.infinity, height: imgH,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgPH(imgH))
                      : _imgPH(imgH),
                ),
              ),
              // Discount badge
              if (discount > 0)
                Positioned(
                  top: 0, left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5002B),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text('-$discount%',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
              // Wishlist button
              Positioned(
                top: 7, right: 7,
                child: GestureDetector(
                  onTap: () => setState(() => _wished = !_wished),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08),
                            blurRadius: 4),
                      ],
                    ),
                    child: Icon(
                      _wished ? Icons.favorite : Icons.favorite_border,
                      size: 14,
                      color: _wished
                          ? const Color(0xFFE5002B)
                          : const Color(0xFFBBBBBB),
                    ),
                  ),
                ),
              ),
            ]),
            // ── Info ───────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF222222), height: 1.3)),
                    const SizedBox(height: 5),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 12,
                          color: Color(0xFFFFA41C)),
                      const SizedBox(width: 2),
                      Text(
                          '${rating.toStringAsFixed(1)} (${_fmt(reviews)})',
                          style: const TextStyle(fontSize: 10.5,
                              color: Color(0xFF888888))),
                    ]),
                    const SizedBox(height: 6),
                    if (compareAt != null && compareAt > price) ...[
                      Text('QAR ${price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB12704))),
                      Text('QAR ${compareAt.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 10.5,
                              color: Color(0xFF999999),
                              decoration: TextDecoration.lineThrough)),
                    ] else
                      Text('QAR ${price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111))),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 33,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _addToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7)),
                        ),
                        child: _busy
                            ? const SizedBox(width: 15, height: 15,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Add to Cart',
                                style: TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                      ),
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

  Widget _imgPH(double h) => Container(
    width: double.infinity,
    height: h,
    decoration: const BoxDecoration(
      color: Color(0xFFF5F5F5),
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
    ),
    child: const Center(
      child: Icon(Icons.image_outlined, size: 34, color: Color(0xFFDDDDDD)),
    ),
  );

  Future<void> _addToCart() async {
    setState(() => _busy = true);
    try {
      await CartService.addItem(widget.product['id'] as String, 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.product['name']} added to cart',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ));
    } on ApiException catch (e) {
      if (e.isConflict && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Already in cart'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
