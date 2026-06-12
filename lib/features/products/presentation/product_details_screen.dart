import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/services/api_client.dart';
import '../../../app_shell.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _product;

  bool _reviewsLoading = false;
  List<Map<String, dynamic>> _reviews = [];
  int _reviewTotalCount = 0;

  bool _wishlisted = false;
  bool _wishlistLoading = false;

  int _quantity = 1;
  bool _addingToCart = false;
  bool _alreadyInCart = false;

  bool _descExpanded = false;

  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await CustomerService.getProduct(widget.productId);
      final product = data['data'] as Map<String, dynamic>? ?? data;
      setState(() {
        _product = product;
        _loading = false;
      });
      _loadReviews();
      _checkWishlist();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _reviewsLoading = true);
    try {
      final res = await CustomerService.getProductReviews(widget.productId);
      final data = res['data'] as List<dynamic>? ?? [];
      final meta = res['meta'] as Map<String, dynamic>?;
      setState(() {
        _reviews = data.cast<Map<String, dynamic>>();
        _reviewTotalCount = (meta?['total'] as int?) ?? data.length;
        _reviewsLoading = false;
      });
    } catch (_) {
      setState(() => _reviewsLoading = false);
    }
  }

  Future<void> _checkWishlist() async {
    if (!AuthService.isLoggedIn) return;
    try {
      final list = await WishlistService.getWishlist();
      final isIn = list.any((item) =>
          item['product_id']?.toString() == widget.productId);
      if (mounted) setState(() => _wishlisted = isIn);
    } catch (_) {}
  }

  Future<void> _toggleWishlist() async {
    if (!AuthService.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    final prev = _wishlisted;
    setState(() {
      _wishlisted = !prev;
      _wishlistLoading = true;
    });
    try {
      if (prev) {
        await WishlistService.removeItem(widget.productId);
      } else {
        await WishlistService.addItem(widget.productId);
      }
    } catch (_) {
      if (mounted) setState(() => _wishlisted = prev);
    } finally {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  Future<void> _handleAddToCart() async {
    if (_alreadyInCart) {
      Navigator.pushNamed(context, '/cart');
      return;
    }
    setState(() => _addingToCart = true);
    try {
      await CartService.addItem(widget.productId, _quantity);
      final cartRes = await CartService.getCart();
      final cartData = cartRes['data'] as Map<String, dynamic>?;
      final itemCount = (cartData?['item_count'] as int?) ?? 0;
      if (mounted) {
        CustomerShell.of(context)?.updateCartCount(itemCount);
        setState(() {
          _addingToCart = false;
          _alreadyInCart = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.t('add_to_cart')),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _addingToCart = false);
        if (e.isConflict) {
          setState(() => _alreadyInCart = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _addingToCart = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.t('error_generic')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openWriteReview() {
    int selectedRating = 0;
    final commentController = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  LocaleService.t('write_review'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedRating = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          i < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: const Color(0xFFFFC107),
                          size: 36,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: LocaleService.t('write_review'),
                    hintStyle: const TextStyle(
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(
                              color: AppColors.divider),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(LocaleService.t('cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: submitting || selectedRating == 0
                            ? null
                            : () async {
                                setSheetState(() => submitting = true);
                                try {
                                  await CustomerService.addReview(
                                    widget.productId,
                                    selectedRating,
                                    commentController.text.trim(),
                                  );
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    _loadReviews();
                                  }
                                } catch (_) {
                                  if (ctx.mounted) {
                                    setSheetState(
                                        () => submitting = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : Text(LocaleService.t('done')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 56, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  LocaleService.t('error_generic'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(LocaleService.t('retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final product = _product!;
    // images is List<String> (plain URL strings from JSONB column).
    // Guard against both String elements and legacy Map elements.
    final rawImages = product['images'] as List<dynamic>? ?? [];
    final images = rawImages
        .map<String?>((e) {
          if (e is String && e.isNotEmpty) return e;
          if (e is Map) return e['url']?.toString();
          return null;
        })
        .whereType<String>()
        .toList();
    final imageCount = images.isEmpty ? 1 : images.length;
    final comparePrice =
        (product['compare_at_price'] as num?)?.toDouble();
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final isSale =
        comparePrice != null && comparePrice > price;
    // Backend returns flat fields from SQL JOIN aliases, not nested objects.
    final categoryName = product['category_name']?.toString();
    final avgRating =
        (product['average_rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = (product['review_count'] as num?)?.toInt() ?? 0;
    final description =
        (product['description'] as String?) ?? '';
    final isActive = product['is_active'] as bool? ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, images, imageCount, isSale),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTagRow(categoryName, isSale, isActive),
                  const SizedBox(height: 10),
                  Text(
                    (product['name'] as String?) ?? '',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildRatingRow(avgRating, reviewCount),
                  const SizedBox(height: 16),
                  _buildPriceAndQuantity(price, comparePrice),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 20),
                  if (description.isNotEmpty) ...[
                    _buildDescriptionSection(description),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 20),
                  ],
                  _buildReviewsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    List<String> images,
    int imageCount,
    bool isSale,
  ) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppColors.background,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back,
              color: AppColors.textPrimary),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _wishlistLoading ? null : _toggleWishlist,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _wishlistLoading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      _wishlisted
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _wishlisted
                          ? const Color(0xFFFF6B6B)
                          : AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.share_outlined,
                color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: imageCount,
              onPageChanged: (i) =>
                  setState(() => _currentImageIndex = i),
              itemBuilder: (context, index) {
                if (images.isNotEmpty) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : _imagePlaceholder(),
                  );
                }
                return _imagePlaceholder();
              },
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imageCount, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentImageIndex == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == i
                          ? AppColors.secondary
                          : Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD4F5E9), Color(0xFFA8E0D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.shopping_basket_outlined,
          size: 100,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildTagRow(
      String? categoryName, bool isSale, bool isActive) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (categoryName != null && categoryName.isNotEmpty)
          _PdTag(label: categoryName),
        if (isSale)
          const _PdTag(label: 'Sale', highlight: true),
        _PdTag(
          label: isActive
              ? LocaleService.t('in_stock')
              : LocaleService.t('out_of_stock'),
          highlight: isActive,
          color: isActive
              ? const Color(0xFF2ECC71)
              : const Color(0xFFFF6B6B),
        ),
      ],
    );
  }

  Widget _buildRatingRow(double avgRating, int reviewCount) {
    final stars = avgRating.clamp(0.0, 5.0);
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < stars.floor()) {
            return const Icon(Icons.star,
                color: Color(0xFFFFC107), size: 16);
          } else if (i < stars && stars - i >= 0.5) {
            return const Icon(Icons.star_half,
                color: Color(0xFFFFC107), size: 16);
          }
          return const Icon(Icons.star_border,
              color: Color(0xFFFFC107), size: 16);
        }),
        const SizedBox(width: 8),
        Text(
          avgRating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($reviewCount ${LocaleService.t('reviews')})',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPriceAndQuantity(
      double price, double? comparePrice) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${LocaleService.t('qar')} ${price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
            if (comparePrice != null &&
                comparePrice > price) ...[
              const SizedBox(height: 2),
              Text(
                '${LocaleService.t('qar')} ${comparePrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.7),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: () {
                  if (_quantity > 1) {
                    setState(() => _quantity--);
                  }
                },
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add,
                onTap: () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(String description) {
    final isLong = description.length > 200;
    final displayText = isLong && !_descExpanded
        ? '${description.substring(0, 200)}...'
        : description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleService.t('description'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          displayText,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        if (isLong) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () =>
                setState(() => _descExpanded = !_descExpanded),
            child: Text(
              _descExpanded ? 'Show less' : 'Show more',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LocaleService.t('reviews'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (_reviewTotalCount > 0)
              Text(
                '$_reviewTotalCount ${LocaleService.t('reviews')}',
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_reviewsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                  color: AppColors.secondary, strokeWidth: 2),
            ),
          )
        else if (_reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(
              child: Text(
                LocaleService.t('no_reviews'),
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14),
              ),
            ),
          )
        else ...[
          ...(_reviews.take(3).map((r) => _ReviewCard(review: r))),
          if (_reviewTotalCount > 3) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  'See all $_reviewTotalCount ${LocaleService.t('reviews')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
          ],
        ],
        if (AuthService.isLoggedIn) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openWriteReview,
              icon: const Icon(Icons.rate_review_outlined,
                  size: 18),
              label: Text(LocaleService.t('write_review')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
                padding:
                    const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/cart'),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  color: AppColors.secondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _addingToCart ? null : _handleAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.secondary.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _addingToCart
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      _alreadyInCart
                          ? 'Go to Cart'
                          : LocaleService.t('add_to_cart'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Map<String, dynamic> review;

  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] as int?) ?? 0;
    final comment = (review['comment'] as String?) ?? '';
    final user = review['user'] as Map<String, dynamic>?;
    final name = (user?['full_name'] as String?) ?? 'Anonymous';
    final createdAt = (review['created_at'] as String?) ?? '';
    String dateLabel = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateLabel =
            '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < rating ? Icons.star : Icons.star_border,
                color: const Color(0xFFFFC107),
                size: 14,
              );
            }),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _PdTag extends StatelessWidget {
  const _PdTag(
      {required this.label,
      this.highlight = false,
      this.color});

  final String label;
  final bool highlight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? (highlight ? AppColors.secondary : null);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor != null
            ? effectiveColor.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: effectiveColor != null
              ? effectiveColor.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: effectiveColor ?? AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 18, color: AppColors.secondary),
      ),
    );
  }
}
