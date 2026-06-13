import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/api_client.dart';
import '../../products/presentation/product_details_screen.dart';
import '../../products/presentation/product_listing_screen.dart';
import '../../cart/presentation/cart_screen.dart';

// ── Collection imagery ────────────────────────────────────────────────────────
// Each category maps to a product image used as the collection's visual card.
const _kCollImg = <String, String>{
  'cat_1':  'img/products/p3.png',
  'cat_2':  'img/products/p11.png',
  'cat_3':  'img/products/p27.png',
  'cat_4':  'img/products/p19.png',
  'cat_5':  'img/products/p35.png',
  'cat_6':  'img/products/p41.png',
  'cat_7':  'img/products/p47.png',
  'cat_8':  'img/products/p51.png',
  'cat_9':  'img/products/p39.png',
  'cat_10': 'img/products/p22.png',
  'cat_11': 'img/products/p8.png',
  'cat_12': 'img/products/p30.png',
};

// ── HomeScreen ────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _categories  = [];
  List<Map<String, dynamic>> _trending    = [];
  List<Map<String, dynamic>> _flashDeals  = [];
  List<Map<String, dynamic>> _newArrivals = [];
  bool _loading = true;

  Duration _flashLeft = const Duration(hours: 3, minutes: 47, seconds: 11);
  Timer? _flashTimer;

  late final AnimationController _enterCtrl;
  late final Animation<double>   _enterFade;
  late final Animation<Offset>   _enterSlide;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _enterFade  = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterSlide = Tween(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));
    _enterCtrl.forward();

    _flashTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_flashLeft.inSeconds > 0) _flashLeft -= const Duration(seconds: 1);
      });
    });

    _loadAll();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _flashTimer?.cancel();
    super.dispose();
  }

  static List<Map<String, dynamic>> _parse(Map<String, dynamic> r) {
    final raw = r['data'];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _loadAll() async {
    try {
      final cats  = await CustomerService.getCategories();
      final trend = await CustomerService.getProducts(sort: 'top_rated',  limit: 10);
      final flash = await CustomerService.getProducts(flashDeals: true,   limit: 8);
      final newA  = await CustomerService.getProducts(sort: 'newest',     limit: 10);
      if (!mounted) return;
      setState(() {
        _categories  = cats;
        _trending    = _parse(trend);
        _flashDeals  = _parse(flash);
        _newArrivals = _parse(newA);
        _loading     = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _push(Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  void _go(Map<String, dynamic> p) =>
      _push(ProductDetailsScreen(productId: p['id'] as String));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: AppColors.primary,
        displacement: 80,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _enterFade,
                child: SlideTransition(
                  position: _enterSlide,
                  child: _buildBody(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar — stripped to essentials ─────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 54,
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFF0F0F0)),
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('Q',
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w900, height: 1)),
          ),
          const SizedBox(width: 9),
          const Text('Q Cart',
              style: TextStyle(color: Color(0xFF0D0D0D), fontSize: 17,
                  fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          const Spacer(),
          GestureDetector(
            onTap: () => _push(const ProductListingScreen()),
            child: const Icon(Icons.search_rounded,
                color: Color(0xFF0D0D0D), size: 22),
          ),
          const SizedBox(width: 18),
          GestureDetector(
            onTap: () => _push(const CartScreen()),
            child: const Icon(Icons.shopping_bag_outlined,
                color: Color(0xFF0D0D0D), size: 22),
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
        _buildHero(),
        _buildCollections(),
        _buildSection(
          label: 'Trending Now',
          items: _trending,
          onSeeAll: () => _push(const ProductListingScreen(
              title: 'Trending', sort: 'top_rated')),
        ),
        _buildFlashDeals(),
        _buildSection(
          label: 'Just Arrived',
          items: _newArrivals,
          onSeeAll: () => _push(const ProductListingScreen(
              title: 'New Arrivals', sort: 'newest')),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  // ── Hero — full-bleed editorial ───────────────────────────────────────────

  Widget _buildHero() {
    return GestureDetector(
      onTap: () => _push(const ProductListingScreen(
          title: 'Featured', featured: true)),
      child: SizedBox(
        width: double.infinity,
        height: 320,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image — full bleed, covers entire hero
            Image.network(
              'img/products/p1.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF141414)),
            ),
            // Gradient overlay: clear at top, dark at bottom
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.72),
                  ],
                  stops: const [0.30, 1.0],
                ),
              ),
            ),
            // Text overlay — anchored to bottom
            Positioned(
              bottom: 28, left: 24, right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Eyebrow
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.28), width: 0.5),
                    ),
                    child: const Text('Q CART SELECTS',
                        style: TextStyle(color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w600, letterSpacing: 1.8)),
                  ),
                  const SizedBox(height: 12),
                  // Headline
                  const Text(
                    'The New\nSeason Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // CTA pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text('Explore Now',
                        style: TextStyle(color: Color(0xFF0D0D0D),
                            fontSize: 13.5, fontWeight: FontWeight.w700,
                            letterSpacing: -0.2)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Collections — photographic editorial cards ────────────────────────────

  Widget _buildCollections() {
    final cats = _loading
        ? List.generate(8, (i) => {'id': 'cat_${i + 1}', 'name': ''})
        : _categories.take(8).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(children: [
            const Text('Collections',
                style: TextStyle(color: Color(0xFF0D0D0D), fontSize: 22,
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const Spacer(),
            GestureDetector(
              onTap: () => _push(const ProductListingScreen()),
              child: const Text('See All',
                  style: TextStyle(color: AppColors.primary, fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        SizedBox(
          height: 175,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            itemCount: cats.length,
            itemBuilder: (_, i) {
              final cat   = cats[i];
              final catId = cat['id'] as String? ?? 'cat_${i + 1}';
              final name  = cat['name'] as String? ?? '';
              if (_loading) {
                return Container(
                  width: 155, height: 175,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              }
              final img = _kCollImg[catId] ??
                  'img/products/p${(i % 12) + 1}.png';
              return GestureDetector(
                onTap: () => _push(ProductListingScreen(
                    title: name, categoryId: catId)),
                child: Container(
                  width: 155, height: 175,
                  margin: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.network(img, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: Color(0xFF1A1A1A))),
                      // Bottom-weighted gradient overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.68),
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                      // Collection name
                      Positioned(
                        bottom: 12, left: 12, right: 12,
                        child: Text(name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2)),
                      ),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ── Flash Deals — editorial header, inline countdown ─────────────────────

  Widget _buildFlashDeals() {
    final h  = _flashLeft.inHours;
    final m  = _flashLeft.inMinutes % 60;
    final s  = _flashLeft.inSeconds % 60;
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Flash Deals',
                    style: TextStyle(color: Color(0xFF0D0D0D), fontSize: 22,
                        fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 3),
                Row(children: [
                  Text('Ends in ',
                      style: TextStyle(fontSize: 12,
                          color: const Color(0xFF888888))),
                  Text('$hh:$mm:$ss',
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE5002B))),
                ]),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: () => _push(const ProductListingScreen(
                    title: 'Flash Deals')),
                child: const Text('See All',
                    style: TextStyle(color: AppColors.primary, fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 292,
          child: _loading
              ? _skRow()
              : _flashDeals.isEmpty
                  ? _emptyHint()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      itemCount: _flashDeals.length,
                      itemBuilder: (_, i) => _PremiumCard(
                        product: _flashDeals[i],
                        onTap: () => _go(_flashDeals[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  // ── Generic product section ───────────────────────────────────────────────

  Widget _buildSection({
    required String label,
    required List<Map<String, dynamic>> items,
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(children: [
            Text(label,
                style: const TextStyle(color: Color(0xFF0D0D0D), fontSize: 22,
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const Spacer(),
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('See All',
                  style: TextStyle(color: AppColors.primary, fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        SizedBox(
          height: 292,
          child: _loading
              ? _skRow()
              : items.isEmpty
                  ? _emptyHint()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _PremiumCard(
                        product: items[i],
                        onTap: () => _go(items[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  // ── Skeleton ─────────────────────────────────────────────────────────────

  Widget _skRow() => ListView.builder(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
    itemCount: 4,
    itemBuilder: (_, __) => Container(
      width: 185, height: 292,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  Widget _emptyHint() => const Center(
    child: Text('Nothing here yet',
        style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
  );
}

// ── Premium Product Card ──────────────────────────────────────────────────────

class _PremiumCard extends StatefulWidget {
  const _PremiumCard({required this.product, required this.onTap});
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  @override
  State<_PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<_PremiumCard> {
  bool _busy   = false;
  bool _wished = false;

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  String? _imgUrl() {
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
    final imgUrl    = _imgUrl();
    final discount  = (compareAt != null && compareAt > price)
        ? ((1 - price / compareAt) * 100).round()
        : 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 185,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image area ─────────────────────────────────────────────
              Stack(children: [
                SizedBox(
                  width: 185,
                  height: 168,
                  child: imgUrl != null
                      ? Image.network(imgUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgPH())
                      : _imgPH(),
                ),
                if (discount > 0)
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5002B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('-$discount%',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: () => setState(() => _wished = !_wished),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8)],
                      ),
                      child: Icon(
                        _wished ? Icons.favorite : Icons.favorite_border,
                        size: 15,
                        color: _wished
                            ? const Color(0xFFE5002B)
                            : const Color(0xFF999999),
                      ),
                    ),
                  ),
                ),
              ]),
              // ── Info area ──────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(name,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: Color(0xFF111111), letterSpacing: -0.1)),
                      const SizedBox(height: 4),
                      // Rating
                      Row(children: [
                        const Icon(Icons.star_rounded, size: 12,
                            color: Color(0xFFFFA41C)),
                        const SizedBox(width: 3),
                        Text('${rating.toStringAsFixed(1)} '
                            '(${_fmt(reviews)})',
                            style: const TextStyle(fontSize: 10.5,
                                color: Color(0xFF888888))),
                      ]),
                      const SizedBox(height: 7),
                      // Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('QAR ${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: discount > 0
                                      ? const Color(0xFFB12704)
                                      : const Color(0xFF111111))),
                          if (compareAt != null && compareAt > price) ...[
                            const SizedBox(width: 6),
                            Text('QAR ${compareAt.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF999999),
                                    decoration: TextDecoration.lineThrough)),
                          ],
                        ],
                      ),
                      const Spacer(),
                      // Add to Cart
                      SizedBox(
                        width: double.infinity,
                        height: 36,
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
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _busy
                              ? const SizedBox(width: 15, height: 15,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Add to Cart',
                                  style: TextStyle(fontSize: 12.5,
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
      ),
    );
  }

  Widget _imgPH() => Container(
    width: 185, height: 168,
    color: const Color(0xFFF3F3F3),
    child: const Center(
        child: Icon(Icons.image_outlined, size: 32,
            color: Color(0xFFDDDDDD))),
  );

  Future<void> _addToCart() async {
    setState(() => _busy = true);
    try {
      await CartService.addItem(widget.product['id'] as String, 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.product['name']} added to cart',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF111111),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
