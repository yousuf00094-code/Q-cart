import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/api_client.dart';
import '../../products/presentation/product_details_screen.dart';
import '../../products/presentation/product_listing_screen.dart';
import '../../cart/presentation/cart_screen.dart';

// ── Banner data ───────────────────────────────────────────────────────────────

class _BannerSlide {
  final String badge;
  final String title;
  final String sub;
  final Color c1;
  final Color c2;
  const _BannerSlide(this.badge, this.title, this.sub, this.c1, this.c2);
}

const _banners = [
  _BannerSlide('SALE', 'Exclusive Tech\nDeals', 'Up to 40% off Electronics',
      Color(0xFF1A1758), Color(0xFF4B44C8)),
  _BannerSlide('NEW', 'New Arrivals', 'Fresh styles updated daily',
      Color(0xFF0D5C7A), Color(0xFF1BA8BF)),
  _BannerSlide('FLASH', 'Flash Sale\nToday', 'Deals ending in hours!',
      Color(0xFF8B1A1A), Color(0xFFC43030)),
  _BannerSlide('FREE', 'Free Delivery', 'On orders over QAR 100',
      Color(0xFF1B4332), Color(0xFF2D6A4F)),
];

// ── Category icon map ─────────────────────────────────────────────────────────

const _catMeta = <String, (IconData, Color, Color)>{
  'cat_1':  (Icons.devices_other,       Color(0xFF1565C0), Color(0xFFE3F2FD)),
  'cat_2':  (Icons.checkroom,           Color(0xFFAD1457), Color(0xFFFCE4EC)),
  'cat_3':  (Icons.home,                Color(0xFF2E7D32), Color(0xFFE8F5E9)),
  'cat_4':  (Icons.spa,                 Color(0xFF6A1B9A), Color(0xFFF3E5F5)),
  'cat_5':  (Icons.fitness_center,      Color(0xFFC62828), Color(0xFFFFEBEE)),
  'cat_6':  (Icons.local_grocery_store, Color(0xFFE65100), Color(0xFFFFF3E0)),
  'cat_7':  (Icons.menu_book,           Color(0xFF283593), Color(0xFFE8EAF6)),
  'cat_8':  (Icons.toys,                Color(0xFFE65100), Color(0xFFFFF3E0)),
  'cat_9':  (Icons.directions_car,      Color(0xFF424242), Color(0xFFF5F5F5)),
  'cat_10': (Icons.favorite,            Color(0xFF00695C), Color(0xFFE0F2F1)),
  'cat_11': (Icons.diamond,             Color(0xFFF57F17), Color(0xFFFFFDE7)),
  'cat_12': (Icons.child_care,          Color(0xFF880E4F), Color(0xFFFCE4EC)),
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

  final PageController _bannerCtrl = PageController();
  int _bannerPage = 0;
  Timer? _bannerTimer;

  Duration _flashRemaining = const Duration(hours: 2, minutes: 47, seconds: 33);
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

  // ── Data ──────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _parseProducts(Map<String, dynamic> res) {
    final raw = res['data'];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _loadAll() async {
    try {
      final catsFut = CustomerService.getCategories();
      final bsFut   = CustomerService.getProducts(sort: 'sold_desc', limit: 10);
      final featFut = CustomerService.getProducts(featured: true, limit: 10);
      final newFut  = CustomerService.getProducts(sort: 'newest', limit: 10);
      final flashFut = CustomerService.getProducts(flashDeals: true, limit: 8);

      final cats  = await catsFut;
      final bs    = await bsFut;
      final feat  = await featFut;
      final newA  = await newFut;
      final flash = await flashFut;

      if (!mounted) return;
      setState(() {
        _categories  = cats;
        _bestSelling = _parseProducts(bs);
        _featured    = _parseProducts(feat);
        _newArrivals = _parseProducts(newA);
        _flashDeals  = _parseProducts(flash);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_bannerPage + 1) % _banners.length;
      _bannerCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _bannerPage = next);
    });
  }

  void _startFlashTimer() {
    _flashTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_flashRemaining.inSeconds > 0) {
          _flashRemaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  String get _timerText {
    final h = _flashRemaining.inHours.toString().padLeft(2, '0');
    final m = (_flashRemaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_flashRemaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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

  // ── App bar ───────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.black12,
      titleSpacing: 16,
      title: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF3B2E9E), Color(0xFF6B5FD5)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: const Text('Q',
              style: TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w900, height: 1)),
        ),
        const SizedBox(width: 8),
        RichText(text: const TextSpan(children: [
          TextSpan(text: 'Q',
              style: TextStyle(color: AppColors.primary, fontSize: 20,
                  fontWeight: FontWeight.w800)),
          TextSpan(text: ' Cart',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 20,
                  fontWeight: FontWeight.w600)),
        ])),
      ]),
      actions: [
        GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('AR',
                style: TextStyle(color: AppColors.primary, fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CartScreen())),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: _buildSearchBar(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ProductListingScreen())),
      child: Container(
        height: 44,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F1F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 20, color: Color(0xFF9E9E9E)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Search products...',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroBanner(),
        const SizedBox(height: 10),
        _buildCategoryStrip(),
        const SizedBox(height: 10),
        if (!_loading && _flashDeals.isNotEmpty) ...[
          _buildFlashDeals(),
          const SizedBox(height: 10),
        ],
        _buildSection(
          title: 'Best Sellers',
          items: _bestSelling,
          icon: const Icon(Icons.trending_up, size: 17, color: AppColors.accent),
          onSeeAll: () => _push(const ProductListingScreen(
              title: 'Best Sellers', sort: 'sold_desc')),
        ),
        const SizedBox(height: 10),
        _buildMidBanner(),
        const SizedBox(height: 10),
        _buildSection(
          title: 'New Arrivals',
          items: _newArrivals,
          icon: const Icon(Icons.fiber_new, size: 17, color: Color(0xFF2D6A4F)),
          onSeeAll: () => _push(const ProductListingScreen(
              title: 'New Arrivals', sort: 'newest')),
        ),
        const SizedBox(height: 10),
        _buildSection(
          title: 'Featured Products',
          items: _featured,
          icon: const Icon(Icons.star_rounded, size: 17,
              color: AppColors.ratingGold),
          onSeeAll: () => _push(const ProductListingScreen(
              title: 'Featured Products', featured: true)),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  // ── Hero banner ───────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    return SizedBox(
      height: 188,
      child: Stack(children: [
        PageView.builder(
          controller: _bannerCtrl,
          itemCount: _banners.length,
          onPageChanged: (i) => setState(() => _bannerPage = i),
          itemBuilder: (_, i) => _bannerSlide(_banners[i]),
        ),
        Positioned(
          bottom: 10, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _bannerPage == i ? 18 : 6, height: 6,
              decoration: BoxDecoration(
                color: _bannerPage == i ? Colors.white : Colors.white54,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        ),
      ]),
    );
  }

  Widget _bannerSlide(_BannerSlide b) {
    return GestureDetector(
      onTap: () => _push(const ProductListingScreen()),
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(
          colors: [b.c1, b.c2],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        )),
        child: Stack(children: [
          Positioned(right: -30, top: -30,
              child: _disc(180, Colors.white, 0.07)),
          Positioned(right: 30, bottom: -40,
              child: _disc(130, Colors.white, 0.05)),
          Positioned(left: -20, bottom: -20,
              child: _disc(80,  Colors.white, 0.04)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 100, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(b.badge,
                      style: const TextStyle(color: Color(0xFF1C1A2E),
                          fontSize: 11, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                Text(b.title,
                    style: const TextStyle(color: Colors.white, fontSize: 21,
                        fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 6),
                Text(b.sub,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Shop Now',
                        style: TextStyle(color: b.c1, fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 13, color: b.c1),
                  ]),
                ),
              ],
            ),
          ),
          // Discount badge
          Positioned(right: 16, top: 0, bottom: 0,
            child: Center(child: Container(
              width: 78, height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 2),
              ),
              alignment: Alignment.center,
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('UP TO', style: TextStyle(color: Colors.white60, fontSize: 8)),
                Text('40%', style: TextStyle(color: Colors.white,
                    fontSize: 22, fontWeight: FontWeight.w900)),
                Text('OFF', style: TextStyle(color: Colors.white60, fontSize: 8)),
              ]),
            )),
          ),
        ]),
      ),
    );
  }

  Widget _disc(double s, Color c, double o) =>
      Container(width: s, height: s,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: c.withOpacity(o)));

  // ── Category strip ────────────────────────────────────────────────────────

  Widget _buildCategoryStrip() {
    final cats = _loading
        ? List.generate(8, (i) => {'id': 'cat_${i+1}', 'name': ''})
        : _categories;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(children: [
            const Text('Shop by Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => _push(const ProductListingScreen()),
              child: const Text('See all',
                  style: TextStyle(fontSize: 13, color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: cats.length,
            itemBuilder: (_, i) {
              final cat   = cats[i];
              final catId = cat['id'] as String;
              final name  = cat['name'] as String? ?? '';
              if (_loading) return _skCatItem();
              final meta = _catMeta[catId];
              final icon  = meta?.$1 ?? Icons.category;
              final icoC  = meta?.$2 ?? AppColors.primary;
              final bgC   = meta?.$3 ?? const Color(0xFFE8EAF6);
              return GestureDetector(
                onTap: () => _push(ProductListingScreen(
                    title: name, categoryId: catId)),
                child: SizedBox(
                  width: 74,
                  child: Column(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: bgC, shape: BoxShape.circle),
                      child: Icon(icon, size: 27, color: icoC),
                    ),
                    const SizedBox(height: 5),
                    Text(name,
                        textAlign: TextAlign.center, maxLines: 2,
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
    return Container(
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            const Icon(Icons.bolt_rounded, color: AppColors.flashRed, size: 22),
            const SizedBox(width: 4),
            const Text('Flash Deals',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.flashRed,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_timerText,
                  style: const TextStyle(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w700,
                      )),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _push(const ProductListingScreen()),
              child: const Text('See all',
                  style: TextStyle(fontSize: 13, color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: _flashDeals.length,
            itemBuilder: (_, i) => _QProductCard(
              product: _flashDeals[i], compact: true,
              onTap: () => _openProduct(_flashDeals[i]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Generic product section ───────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> items,
    required Widget icon,
    required VoidCallback onSeeAll,
  }) {
    return Container(
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Container(width: 4, height: 20,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 6),
            icon,
            const Spacer(),
            GestureDetector(
              onTap: onSeeAll,
              child: Row(children: const [
                Text('See all',
                    style: TextStyle(fontSize: 13, color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
              ]),
            ),
          ]),
        ),
        SizedBox(
          height: 250,
          child: _loading
              ? _skProductRow()
              : items.isEmpty
                  ? _emptySection()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _QProductCard(
                        product: items[i],
                        onTap: () => _openProduct(items[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _emptySection() => const Center(
      child: Text('No products available',
          style: TextStyle(color: AppColors.textSecondary)));

  // ── Mid banner ────────────────────────────────────────────────────────────

  Widget _buildMidBanner() {
    return GestureDetector(
      onTap: () => _push(const ProductListingScreen(
          title: 'Beauty & Care', categoryId: 'cat_4')),
      child: Container(
        height: 108,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
        ),
        child: Stack(children: [
          Positioned(right: -20, top: -20,
              child: _disc(120, Colors.white, 0.07)),
          Positioned(right: 60, bottom: -30,
              child: _disc(80, Colors.white, 0.05)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Beauty & Self-Care',
                    style: TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Explore premium skincare & cosmetics',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('Shop Now →',
                      style: TextStyle(color: Color(0xFF6A1B9A), fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _openProduct(Map<String, dynamic> product) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProductDetailsScreen(
            productId: product['id'] as String)));
  }

  // ── Skeletons ─────────────────────────────────────────────────────────────

  Widget _skBox(double w, double h, {double r = 8}) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
        color: const Color(0xFFEDF0F3),
        borderRadius: BorderRadius.circular(r)),
  );

  Widget _skCatItem() => Container(
    width: 74,
    child: Column(children: [
      Container(width: 56, height: 56,
          decoration: const BoxDecoration(
              color: Color(0xFFEDF0F3), shape: BoxShape.circle)),
      const SizedBox(height: 5),
      _skBox(44, 9),
    ]),
  );

  Widget _skProductRow({bool compact = false}) {
    final w = compact ? 140.0 : 160.0;
    final imgH = compact ? 105.0 : 125.0;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        width: w,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _skBox(w, imgH, r: 12),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _skBox(w - 16, 11),
              const SizedBox(height: 4),
              _skBox((w - 16) * 0.65, 11),
              const SizedBox(height: 7),
              _skBox(55, 10),
              const SizedBox(height: 7),
              _skBox(48, 14),
              const SizedBox(height: 7),
              _skBox(w - 16, 30, r: 7),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Product card ─────────────────────────────────────────────────────────────

class _QProductCard extends StatefulWidget {
  const _QProductCard({
    required this.product,
    required this.onTap,
    this.compact = false,
  });
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_QProductCard> createState() => _QProductCardState();
}

class _QProductCardState extends State<_QProductCard> {
  bool _busy = false;

  String _fmt(int n) => n >= 1000 ? '${(n/1000).toStringAsFixed(1)}k' : '$n';

  String? _imageUrl() {
    final raw = widget.product['images'];
    if (raw is! List || raw.isEmpty) return null;
    final f = raw[0];
    if (f is String && f.isNotEmpty) return f;
    if (f is Map) return f['url']?.toString();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final name      = p['name'] as String? ?? '';
    final price     = (p['price'] as num).toDouble();
    final compareAt = (p['compare_at_price'] as num?)?.toDouble();
    final rating    = (p['average_rating'] as num?)?.toDouble() ?? 0.0;
    final reviews   = p['review_count'] as int? ?? 0;
    final imgUrl    = _imageUrl();
    final discount  = (compareAt != null && compareAt > price)
        ? ((1 - price / compareAt) * 100).round() : 0;

    final cardW = widget.compact ? 142.0 : 162.0;
    final imgH  = widget.compact ? 108.0 : 128.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: cardW,
        margin: const EdgeInsets.only(right: 8, bottom: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: imgUrl != null
                  ? Image.network(imgUrl,
                      width: cardW, height: imgH, fit: BoxFit.cover,
                      loadingBuilder: (_, child, prog) =>
                          prog == null ? child : _imgPH(cardW, imgH),
                      errorBuilder: (_, __, ___) => _imgPH(cardW, imgH))
                  : _imgPH(cardW, imgH),
            ),
            if (discount > 0)
              Positioned(top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.flashRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('-$discount%',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
            Positioned(top: 7, right: 7,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),
                      blurRadius: 4)],
                ),
                child: const Icon(Icons.favorite_border, size: 14,
                    color: AppColors.textSecondary),
              ),
            ),
          ]),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary, height: 1.3)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, size: 13, color: AppColors.ratingGold),
                const SizedBox(width: 2),
                Text('$rating (${_fmt(reviews)})',
                    style: const TextStyle(fontSize: 10.5,
                        color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 5),
              // Price
              if (compareAt != null && compareAt > price) ...[
                Text('QAR ${price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13.5,
                        fontWeight: FontWeight.w700, color: AppColors.priceRed)),
                Text('QAR ${compareAt.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough)),
              ] else
                Text('QAR ${price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13.5,
                        fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              // Add to cart
              SizedBox(
                width: double.infinity, height: 32,
                child: ElevatedButton(
                  onPressed: _busy ? null : _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
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
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _imgPH(double w, double h) => Container(
    width: w, height: h, color: const Color(0xFFF5F5F5),
    child: const Center(child: Icon(Icons.shopping_bag_outlined,
        size: 36, color: Color(0xFFCCCCCC))),
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
          Expanded(child: Text(
              '${widget.product['name']} added to cart',
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ));
    } on ApiException catch (e) {
      if (e.isConflict && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already in cart')),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
