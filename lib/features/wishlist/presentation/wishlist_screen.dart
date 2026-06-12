import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/utils/parse_num.dart';
import '../../../app_shell.dart';
import '../../products/presentation/product_details_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await WishlistService.getWishlist();
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
        CustomerShell.of(context)?.updateWishlistCount(_items.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _moveToCart(
      Map<String, dynamic> item, int index) async {
    final productId = item['product_id']?.toString() ?? '';
    try {
      await CartService.addItem(productId, 1);
      await WishlistService.removeItem(productId);
      if (mounted) {
        setState(() => _items.removeAt(index));
        CustomerShell.of(context)
            ?.updateWishlistCount(_items.length);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${(item['product'] as Map<String, dynamic>?)?['name'] ?? ''} moved to cart'),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
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

  Future<void> _removeItem(
      Map<String, dynamic> item, int index) async {
    final productId = item['product_id']?.toString() ?? '';
    final removed = item;
    setState(() => _items.removeAt(index));
    CustomerShell.of(context)
        ?.updateWishlistCount(_items.length);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${(removed['product'] as Map<String, dynamic>?)?['name'] ?? ''} ${LocaleService.t('remove')}d'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primary,
          onPressed: () async {
            try {
              await WishlistService.addItem(productId);
              if (mounted) {
                setState(() => _items.insert(index, removed));
                CustomerShell.of(context)
                    ?.updateWishlistCount(_items.length);
              }
            } catch (_) {}
          },
        ),
      ),
    );

    try {
      await WishlistService.removeItem(productId);
    } catch (_) {
      if (mounted) {
        setState(() => _items.insert(index, removed));
        CustomerShell.of(context)
            ?.updateWishlistCount(_items.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: _loadWishlist,
        child: _buildBody(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final count = _items.length;
    final label = count == 1
        ? '1 ${LocaleService.t('item')}'
        : '$count ${LocaleService.t('items')}';
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleService.t('my_wishlist'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (!_loading && _error == null)
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.secondary),
      );
    }
    if (_error != null) {
      return Center(
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
                    color: AppColors.textSecondary,
                    fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadWishlist,
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
      );
    }
    if (_items.isEmpty) {
      return _buildEmptyState();
    }
    return _buildGrid(context);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 48,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              LocaleService.t('empty_wishlist'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _WishlistItemCard(
                item: _items[index],
                onMoveToCart: () =>
                    _moveToCart(_items[index], index),
                onRemove: () =>
                    _removeItem(_items[index], index),
                onTap: () {
                  final productId =
                      _items[index]['product_id']?.toString() ??
                          '';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(
                          productId: productId),
                    ),
                  );
                },
              ),
              childCount: _items.length,
            ),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _WishlistItemCard extends StatefulWidget {
  const _WishlistItemCard({
    required this.item,
    required this.onMoveToCart,
    required this.onRemove,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final VoidCallback onMoveToCart;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  State<_WishlistItemCard> createState() =>
      _WishlistItemCardState();
}

class _WishlistItemCardState
    extends State<_WishlistItemCard> {
  bool _movingToCart = false;

  @override
  Widget build(BuildContext context) {
    final product =
        widget.item['product'] as Map<String, dynamic>?;
    final name = (product?['name'] as String?) ?? '';
    final price = parseDouble(product?['price']);
    final rawImages = product?['images'] as List<dynamic>? ?? [];
    final imageUrl = rawImages.isNotEmpty
        ? (rawImages.first is String
            ? rawImages.first as String
            : rawImages.first is Map
                ? rawImages.first['url']?.toString()
                : null)
        : null;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: imageUrl != null &&
                        imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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
                  const SizedBox(height: 4),
                  Text(
                    '${LocaleService.t('qar')} ${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _movingToCart
                              ? null
                              : () async {
                                  setState(
                                      () => _movingToCart = true);
                                  widget.onMoveToCart();
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 7),
                            decoration: BoxDecoration(
                              color: _movingToCart
                                  ? AppColors.secondary
                                      .withOpacity(0.7)
                                  : AppColors.secondary,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: _movingToCart
                                ? const Center(
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    LocaleService.t(
                                        'move_to_cart'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: widget.onRemove,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8E8),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFFF6B6B),
                            size: 16,
                          ),
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

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD4F5E9), Color(0xFFA8E0D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.shopping_basket_outlined,
        size: 44,
        color: Colors.white70,
      ),
    );
  }
}
