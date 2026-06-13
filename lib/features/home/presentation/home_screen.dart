import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/api_client.dart';
import '../../products/presentation/product_details_screen.dart';
import '../../products/presentation/product_listing_screen.dart';
import '../../cart/presentation/cart_screen.dart';

// ── Banner slides ─────────────────────────────────────────────────────────────

class _BannerData {
  final String badge;
  final String headline;
  final String img;
  final Color c1;
  final Color c2;
  const _BannerData(this.badge, this.headline, this.img, this.c1, this.c2);
}

const _kBanners = [
  _BannerData('UP TO 50% OFF', 'Electronics\nWeek',
      'img/products/p1.png', Color(0xFF0F0A3C), Color(0xFF3B2E9E)),
  _BannerData('NEW ARRIVAL', 'Style Drop\nThis Week',
      'img/products/p10.png', Color(0xFF1A0033), Color(0xFF9B1F6A)),
  _BannerData('FLASH SALE', 'Flash Sale\nEnds Today',
      'img/products/p4.png', Color(0xFF3D0000), Color(0xFFBF1616)),
  _BannerData('FREE SHIP', 'Free Delivery\nQAR 99+',
      'img/products/p28.png', Color(0xFF003322), Color(0xFF0D6E4F)),
];

// ── Category icon map ─────────────────────────────────────────────────────────

const _kCatMeta = <String, (IconData, Color, Color)>{
  'cat_1':  (Icons.phone_android,       Color(0xFF1565C0), Color(0xFFE3F2FD)),
  'cat_2':  (Icons.dry_cleaning,        Color(0xFF880E4F), Color(0xFFFCE4EC)),
  'cat_3':  (Icons.chair,               Color(0xFF2E7D32), Color(0xFFE8F5E9)),
  'cat_4':  (Icons.spa,                 Color(0xFF6A1B9A), Color(0xFFF3E5F5)),
  'cat_5':  (Icons.fitness_center,      Color(0xFFC62828), Color(0xFFFFEBEE)),
  'cat_6':  (Icons.local_grocery_store, Color(0xFFE65100), Color(0xFFFFF3E0)),
  'cat_7':  (Icons.auto_stories,        Color(0xFF1A237E), Color(0xFFE8EAF6)),
  'cat_8':  (Icons.sports_esports,      Color(0xFF4527A0), Color(0xFFEDE7F6)),
  'cat_9':  (Icons.directions_car,      Color(0xFF37474F), Color(0xFFECEFF1)),
  'cat_10': (Icons.health_and_safety,   Color(0xFF00695C), Color(0xFFE0F2F1)),
  'cat_11': (Icons.diamond,             Color(0xFFB7971A), Color(0xFFFFFDE7)),
  'cat_12': (Icons.child_friendly,      Color(0xFF6A1B9A), Color(0xFFFCE4EC)),
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
  List<Map<String, dynamic>> _trending    = [];
  bool _loading = true;

  final PageController _bannerCtrl = PageController();
  int _bannerPage = 0;
  Timer? _bannerTimer;

  Duration _flashLeft = const Duration(hours: 1, minutes: 58, seconds: 22);
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _startBannerTimer();
    _startFlashTimer();
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    _bannerTimer?.cancel();
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
      final bs    = await CustomerService.getProducts(sort: 'sold_desc', limit: 12);
      final feat  = await CustomerService.getProducts(featured: true, limit: 10);
      final newA  = await CustomerService.getProducts(sort: 'newest', limit: 10);
      final flash = await CustomerService.getProducts(flashDeals: true, limit: 8);
      final trend = await CustomerService.getProducts(sort: 'top_rated', limit: 8);
      if (!mounted) return;
      setState(() {
        _categories  = cats;
        _bestSelling = _parseProducts(bs);
        _featured    = _parseProducts(feat);
        _newArrivals = _parseProducts(newA);
        _flashDeals  = _parseProducts(flash);
        _trending    = _parseProducts(trend);
        _loading     = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_bannerPage + 1) % _kBanners.length;
      _bannerCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _bannerPage = next);
    });
  }

  void _startFlashTimer() {
    _flashTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_flashLeft.inSeconds > 0) _flashLeft -= const Duration(seconds: 1);
      });
    });
  }

  void _push(Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  void _openProduct(Map<String, dynamic> p) =>
      _push(ProductDetailsScreen(productId: p['id'] as String));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2A1F7A), AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2),
                    blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            alignment: Alignment.center,
            child: const Text('Q',
                style: TextStyle(color: AppColors.primary, fontSize: 18,
                    fontWeight: FontWeight.w900, height: 1)),
          ),
          const SizedBox(width: 8),
          const Text('Q Cart',
              style: TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
          onPressed: () => _push(const CartScreen()),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: _buildSearchBar(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => _push(const ProductListingScreen()),
      child: Container(
        height: 44,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, size: 20, color: Color(0xFF9E9E9E)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Search products, brands...',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13.5)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: const Text('Search',
                style: TextStyle(color: Colors.white, fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(),
        const SizedBox(height: 8),
        _buildPerksStrip(),
        const SizedBox(height: 8),
        _buildCategories(),
        const SizedBox(height: 8),
        _buildFlashDeals(),
        const SizedBox(height: 8),
        _buildProductSection(
          title: 'Best Sellers',
          icon: Icon(Icons.trending_up, size: 18, color: AppColors.accent),
          items: _bestSelling,
          height: 258,
          onSeeAll: () => _push(const ProductListingScreen(
              title: 'Best Sellers', sort: 'sold_desc')),
        ),
        const SizedBox(height: 8),
        _buildTrendingGrid(),
        const SizedBox(height: 8),
        _buildMidBanner(),
        const SizedBox(height: 8),
        _buildProductSection(
          title: 'New Arrivals',
          icon: Icon(Icons.fiber_new, size: 18, color: const Color(0xFF2E7D32)),
          items: _newArrivals,
          height: 258,
          onSeeAll: () => _push(const ProductListingScreen(
              title: 'New Arrivals', sort: 'newest')),
        ),
        const SizedBox(height: 8),
        _buildProductSection(
          title: 'Recommended For You',
          icon: Icon(Icons.auto_awesome, size: 18, color: AppColors.ratingGold),
          items: _featured,
          height: 258,
          onSeeAll: () => _push(const ProductListingScreen(
              title: 'Recommended For You', featured: true)),
        ),
        const SizedBox(height: 8),
        _buildProductSection(
          title: 'Top Rated',
          icon: Icon(Icons.star_rounded, size: 18, color: AppColors.ratingGold),
          items: _trending,
          height: 258,
          onSeeAll: () => _push(const ProductListingScreen(
              title: 'Top Rated', sort: 'top_rated')),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Hero banner ───────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    return SizedBox(
      height: 210,
      child: Stack(children: [
        PageView.builder(
          controller: _bannerCtrl,
          itemCount: _kBanners.length,
          onPageChanged: (i) => setState(() => _bannerPage = i),
          itemBuilder: (_, i) => _buildBannerSlide(_kBanners[i]),
        ),
        Positioned(
          bottom: 10, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_kBanners.length, (i) {
              final active = _bannerPage == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }

  Widget _buildBannerSlide(_BannerData b) {
    return GestureDetector(
      onTap: () => _push(const ProductListingScreen()),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [b.c1, b.c2],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(children: [
          // Decorative circles
          Positioned(right: -30, top: -30,
              child: _circle(160, Colors.white, 0.06)),
          Positioned(left: -20, bottom: -30,
              child: _circle(100, Colors.white, 0.04)),
          // Badge top-right
          Positioned(
            top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(b.badge,
                  style: const TextStyle(color: Color(0xFF1C1A2E),
                      fontSize: 10, fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ),
          ),
          // Product image right side
          Positioned(
            right: 0, top: 0, bottom: 0,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 20),
                child: Image.network(
                  b.img,
                  width: 130,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 130),
                ),
              ),
            ),
          ),
          // Text left side
          Positioned(
            left: 20, top: 0, bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(b.headline,
                    style: const TextStyle(color: Colors.white, fontSize: 26,
                        fontWeight: FontWeight.w800, height: 1.15)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text('Shop Now →',
                      style: TextStyle(color: Colors.white, fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _circle(double s, Color c, double o) => Container(
    width: s, height: s,
    decoration: BoxDecoration(shape: BoxShape.circle,
        color: c.withOpacity(o)),
  );

  // ── Perks strip ───────────────────────────────────────────────────────────

  Widget _buildPerksStrip() {
    final perks = [
      (Icons.local_shipping_outlined, 'Free Delivery', 'On QAR 99+'),
      (Icons.replay_outlined,         '30-Day Return',  'Hassle free'),
      (Icons.lock_outline,            'Secure Pay',     '100% safe'),
      (Icons.verified_outlined,       'Authentic',      'Original brands'),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: List.generate(perks.length * 2 - 1, (idx) {
          if (idx.isOdd) {
            return Container(
              width: 1, height: 36,
              color: const Color(0xFFEEEEEE),
            );
          }
          final i = idx ~/ 2;
          final p = perks[i];
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(p.$1, size: 22, color: AppColors.primary),
                const SizedBox(height: 4),
                Text(p.$2,
                    style: const TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(p.$3,
                    style: const TextStyle(fontSize: 10,
                        color: AppColors.textSecondary)),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Categories ────────────────────────────────────────────────────────────

  Widget _buildCategories() {
    final cats = _loading
        ? List.generate(12, (i) => {'id': 'cat_${i + 1}', 'name': ''})
        : _categories;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            const Text('Categories',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => _push(const ProductListingScreen()),
              child: const Text('See All →',
                  style: TextStyle(fontSize: 13, color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: cats.length,
            itemBuilder: (_, i) {
              final cat   = cats[i];
              final catId = cat['id'] as String? ?? 'cat_${i + 1}';
              final name  = cat['name'] as String? ?? '';
              if (_loading) return _skCatItem();
              final meta = _kCatMeta[catId];
              final icon = meta?.$1 ?? Icons.category;
              final icoC = meta?.$2 ?? AppColors.primary;
              final bgC  = meta?.$3 ?? const Color(0xFFE8EAF6);
              return GestureDetector(
                onTap: () => _push(ProductListingScreen(
                    title: name, categoryId: catId)),
                child: SizedBox(
                  width: 78,
                  child: Column(children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bgC,
                        boxShadow: [
                          BoxShadow(color: icoC.withOpacity(0.18),
                              blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Icon(icon, size: 28, color: icoC),
                    ),
                    const SizedBox(height: 6),
                    Text(name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary, height: 1.2)),
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
    final h = _flashLeft.inHours;
    final m = _flashLeft.inMinutes % 60;
    final s = _flashLeft.inSeconds % 60;
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');

    return Container(
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          color: const Color(0xFFE5002B),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            const Text('⚡ Flash Deals',
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            _timerBox(hh),
            _timerSep(),
            _timerBox(mm),
            _timerSep(),
            _timerBox(ss),
            const Spacer(),
            GestureDetector(
              onTap: () => _push(const ProductListingScreen(
                  title: 'Flash Deals')),
              child: const Text('See All →',
                  style: TextStyle(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        SizedBox(
          height: 240,
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

  Widget _timerBox(String val) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(val,
        style: const TextStyle(color: Color(0xFFE5002B), fontSize: 13,
            fontWeight: FontWeight.w800)),
  );

  Widget _timerSep() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 2),
    child: Text(':', style: TextStyle(color: Colors.white,
        fontSize: 14, fontWeight: FontWeight.w800)),
  );

  // ── Generic product section ───────────────────────────────────────────────

  Widget _buildProductSection({
    required String title,
    required Icon icon,
    required List<Map<String, dynamic>> items,
    required double height,
    required VoidCallback onSeeAll,
  }) {
    return Container(
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            icon,
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: onSeeAll,
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Text('See All',
                    style: TextStyle(fontSize: 13, color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
              ]),
            ),
          ]),
        ),
        SizedBox(
          height: height,
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

  // ── Trending Now grid ─────────────────────────────────────────────────────

  Widget _buildTrendingGrid() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Row(children: [
            const Text('🔥 Trending Now',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => _push(const ProductListingScreen(
                  title: 'Trending Now')),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Text('See All',
                    style: TextStyle(fontSize: 13, color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
              ]),
            ),
          ]),
        ),
        _loading
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, __) => _skGridCard(),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bestSelling.take(4).length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, i) {
                  final item = _bestSelling[i];
                  return _ProductCard(
                    product: item,
                    grid: true,
                    onTap: () => _openProduct(item),
                  );
                },
              ),
      ]),
    );
  }

  // ── Mid banner ────────────────────────────────────────────────────────────

  Widget _buildMidBanner() {
    return GestureDetector(
      onTap: () => _push(const ProductListingScreen(
          title: 'Beauty & Self-Care', categoryId: 'cat_4')),
      child: Container(
        height: 110,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A0080), Color(0xFFAA00FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(children: [
          Positioned(right: -20, top: -30,
              child: _circle(140, Colors.white, 0.07)),
          Positioned(right: 80, bottom: -40,
              child: _circle(90, Colors.white, 0.05)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: const Text('Beauty & Self-Care',
                          style: TextStyle(color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 6),
                    const Text('Premium Skincare\n& Cosmetics',
                        style: TextStyle(color: Colors.white, fontSize: 17,
                            fontWeight: FontWeight.w800, height: 1.2)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text('Shop →',
                    style: TextStyle(color: Color(0xFF4A0080), fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Skeletons ─────────────────────────────────────────────────────────────

  Widget _skBox(double w, double h, {double r = 6}) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
        color: const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(r)),
  );

  Widget _skCatItem() => SizedBox(
    width: 78,
    child: Column(children: [
      Container(width: 60, height: 60,
          decoration: const BoxDecoration(
              color: Color(0xFFECECEC), shape: BoxShape.circle)),
      const SizedBox(height: 6),
      _skBox(46, 9),
    ]),
  );

  Widget _skProductRow({bool compact = false}) {
    final cardW = compact ? 148.0 : 168.0;
    final imgH  = compact ? 118.0 : 135.0;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        width: cardW,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _skBox(cardW, imgH, r: 12),
          Padding(
            padding: const EdgeInsets.all(9),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _skBox(cardW - 18, 11),
              const SizedBox(height: 5),
              _skBox((cardW - 18) * 0.7, 11),
              const SizedBox(height: 8),
              _skBox(55, 10),
              const SizedBox(height: 8),
              _skBox(60, 14),
              const SizedBox(height: 8),
              _skBox(cardW - 18, 32, r: 8),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _skGridCard() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 5, child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFECECEC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      )),
      Expanded(flex: 4, child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _skBox(double.infinity, 11),
          const SizedBox(height: 5),
          _skBox(80, 11),
          const SizedBox(height: 8),
          _skBox(50, 10),
          const SizedBox(height: 8),
          _skBox(60, 14),
          const Spacer(),
          _skBox(double.infinity, 32, r: 8),
        ]),
      )),
    ]),
  );

  Widget _emptyHint() => const Center(
    child: Text('No products available',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
  );
}

// ── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    this.compact = false,
    this.grid = false,
  });
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final bool compact;
  final bool grid;

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

    final double cardW;
    final double imgH;
    if (widget.grid) {
      cardW = double.infinity;
      imgH  = 130;
    } else if (widget.compact) {
      cardW = 148;
      imgH  = 118;
    } else {
      cardW = 168;
      imgH  = 135;
    }

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image area
        Stack(children: [
          SizedBox(
            width: double.infinity,
            height: imgH,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: imgUrl != null
                  ? Image.network(imgUrl,
                      width: double.infinity, height: imgH,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPH(imgH))
                  : _imgPH(imgH),
            ),
          ),
          if (discount > 0)
            Positioned(
              top: 0, left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFE5002B),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text('-$discount%',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 10.5, fontWeight: FontWeight.w800)),
              ),
            ),
          Positioned(
            top: 7, right: 7,
            child: GestureDetector(
              onTap: () => setState(() => _wished = !_wished),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12),
                      blurRadius: 4)],
                ),
                child: Icon(
                  _wished ? Icons.favorite : Icons.favorite_border,
                  size: 15,
                  color: _wished ? Colors.red : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ]),
        // Info
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary, height: 1.3)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 13,
                      color: AppColors.ratingGold),
                  const SizedBox(width: 2),
                  Text('${rating.toStringAsFixed(1)} (${_fmt(reviews)})',
                      style: const TextStyle(fontSize: 10.5,
                          color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 5),
                if (compareAt != null && compareAt > price) ...[
                  Text('QAR ${price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB12704))),
                  Text('QAR ${compareAt.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough)),
                ] else
                  Text('QAR ${price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      disabledBackgroundColor:
                          const Color(0xFFFF6B00).withOpacity(0.5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _busy
                        ? const SizedBox(width: 16, height: 16,
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
    );

    Widget card = Container(
      width: widget.grid ? null : cardW,
      margin: widget.grid
          ? EdgeInsets.zero
          : const EdgeInsets.only(right: 8, bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: cardContent,
    );

    return GestureDetector(onTap: widget.onTap, child: card);
  }

  Widget _imgPH(double h) => Container(
    width: double.infinity,
    height: h,
    color: const Color(0xFFF5F5F5),
    child: const Center(
      child: Icon(Icons.shopping_bag_outlined, size: 38,
          color: Color(0xFFCCCCCC)),
    ),
  );

  Future<void> _addToCart() async {
    setState(() => _busy = true);
    try {
      await CartService.addItem(widget.product['id'] as String, 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${widget.product['name']} added to cart',
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
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
