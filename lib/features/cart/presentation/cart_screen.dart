import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/utils/parse_num.dart';
import '../../../core/utils/category_helpers.dart';
import '../../../app_shell.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  double _subtotal = 0.0;

  final TextEditingController _couponController =
      TextEditingController();
  bool _couponLoading = false;
  Map<String, dynamic>? _appliedCoupon;
  String? _couponError;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await CartService.getCart();
      final data = res['data'] as Map<String, dynamic>?;
      final rawItems = (data?['items'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final sub = parseDouble(data?['subtotal']);
      if (mounted) {
        setState(() {
          _items = rawItems;
          _subtotal = sub;
          _loading = false;
        });
        CustomerShell.of(context)?.updateCartCount(_items.length);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = LocaleService.t('error_generic');
          _loading = false;
        });
      }
    }
  }

  double get _deliveryCost => _subtotal > 200 ? 0.0 : 15.0;

  double get _discountAmount {
    if (_appliedCoupon == null) return 0.0;
    final pct = parseDouble(_appliedCoupon!['discount_percentage']);
    return _subtotal * pct / 100;
  }

  double get _total =>
      _subtotal + _deliveryCost - _discountAmount;

  Future<void> _updateQuantity(
      Map<String, dynamic> item, int newQty) async {
    final itemId = item['id']?.toString() ?? '';
    final oldItems = List<Map<String, dynamic>>.from(_items);
    final oldSubtotal = _subtotal;

    if (newQty <= 0) {
      setState(() {
        _items.removeWhere(
            (i) => i['id']?.toString() == itemId);
        _subtotal = _items.fold(
            0.0,
            (sum, i) =>
                sum +
                parseDouble((i['product'] as Map<String, dynamic>?)?['price']) *
                    parseInt(i['quantity'], 1));
      });
      CustomerShell.of(context)
          ?.updateCartCount(_items.length);
      try {
        await CartService.removeItem(itemId);
      } catch (_) {
        if (mounted) {
          setState(() {
            _items = oldItems;
            _subtotal = oldSubtotal;
          });
          CustomerShell.of(context)
              ?.updateCartCount(_items.length);
        }
      }
      return;
    }

    final idx = _items
        .indexWhere((i) => i['id']?.toString() == itemId);
    if (idx < 0) return;

    setState(() {
      _items[idx] = {
        ..._items[idx],
        'quantity': newQty,
      };
      _subtotal = _items.fold(
          0.0,
          (sum, i) =>
              sum +
              parseDouble((i['product'] as Map<String, dynamic>?)?['price']) *
                  parseInt(i['quantity'], 1));
    });

    try {
      await CartService.updateItem(itemId, newQty);
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = oldItems;
          _subtotal = oldSubtotal;
        });
      }
    }
  }

  Future<void> _removeItem(
      Map<String, dynamic> item, int index) async {
    final itemId = item['id']?.toString() ?? '';
    final oldItems = List<Map<String, dynamic>>.from(_items);
    final oldSubtotal = _subtotal;

    setState(() {
      _items.removeAt(index);
      _subtotal = _items.fold(
          0.0,
          (sum, i) =>
              sum +
              parseDouble((i['product'] as Map<String, dynamic>?)?['price']) *
                  parseInt(i['quantity'], 1));
    });
    CustomerShell.of(context)?.updateCartCount(_items.length);

    try {
      await CartService.removeItem(itemId);
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = oldItems;
          _subtotal = oldSubtotal;
        });
        CustomerShell.of(context)
            ?.updateCartCount(_items.length);
      }
    }
  }

  Future<void> _clearAll() async {
    final oldItems = List<Map<String, dynamic>>.from(_items);
    final oldSubtotal = _subtotal;
    setState(() {
      _items = [];
      _subtotal = 0.0;
    });
    CustomerShell.of(context)?.updateCartCount(0);
    try {
      await CartService.clearCart();
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = oldItems;
          _subtotal = oldSubtotal;
        });
        CustomerShell.of(context)
            ?.updateCartCount(_items.length);
      }
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _couponLoading = true;
      _couponError = null;
      _appliedCoupon = null;
    });
    try {
      final result = await CartService.validateCoupon(code);
      if (mounted) {
        if (result != null) {
          setState(() {
            _appliedCoupon = result;
            _couponLoading = false;
          });
        } else {
          setState(() {
            _couponError = LocaleService.t('invalid_coupon');
            _couponLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _couponError = LocaleService.t('invalid_coupon');
          _couponLoading = false;
        });
      }
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponError = null;
      _couponController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: _loadCart,
        child: _buildBody(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
            LocaleService.t('my_cart'),
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
                  fontSize: 12, color: AppColors.textSecondary),
            ),
        ],
      ),
      actions: [
        if (!_loading && _error == null && _items.isNotEmpty)
          TextButton(
            onPressed: _clearAll,
            child: Text(
              LocaleService.t('clear_all'),
              style: const TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(width: 4),
      ],
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
                    color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadCart,
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
      return _buildEmptyState(context);
    }
    return _buildCartContent(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
              Icons.shopping_cart_outlined,
              size: 48,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            LocaleService.t('empty_cart'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LocaleService.t('start_shopping'),
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              LocaleService.t('start_shopping'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                final itemId = item['id']?.toString() ?? '';
                final product = item['product']
                    as Map<String, dynamic>?;
                final rawImages = product?['images'] as List<dynamic>? ?? [];
                final imageUrl = rawImages.isNotEmpty
                    ? (rawImages.first is String
                        ? rawImages.first as String
                        : rawImages.first is Map
                            ? rawImages.first['url']?.toString()
                            : null)
                    : null;
                final name =
                    (product?['name'] as String?) ?? '';
                final price = parseDouble(product?['price']);
                final qty = parseInt(item['quantity'], 1);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: Key(itemId),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) =>
                        _removeItem(item, index),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8E8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Color(0xFFFF6B6B)),
                    ),
                    child: _CartItemCard(
                      itemId: itemId,
                      name: name,
                      price: price,
                      quantity: qty,
                      imageUrl: imageUrl,
                      onIncrement: () =>
                          _updateQuantity(item, qty + 1),
                      onDecrement: () =>
                          _updateQuantity(item, qty - 1),
                    ),
                  ),
                );
              }),
              _buildCouponSection(),
            ],
          ),
        ),
        _buildOrderSummary(context),
      ],
    );
  }

  Widget _buildCouponSection() {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_appliedCoupon != null) ...[
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Color(0xFF2ECC71), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${LocaleService.t('coupon_applied')}: ${parseDouble(_appliedCoupon!['discount_percentage']).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2ECC71),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _removeCoupon,
                  child: const Icon(Icons.close,
                      color: AppColors.textSecondary,
                      size: 18),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: LocaleService.t('coupon_code'),
                      hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed:
                      _couponLoading ? null : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _couponLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                      : Text(
                          LocaleService.t('apply_coupon'),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
            if (_couponError != null) ...[
              const SizedBox(height: 6),
              Text(
                _couponError!,
                style: const TextStyle(
                    color: Color(0xFFFF6B6B), fontSize: 12),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            LocaleService.t('order_summary'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: LocaleService.t('subtotal'),
            value:
                '${LocaleService.t('qar')} ${_subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: LocaleService.t('delivery'),
            value: _deliveryCost == 0
                ? LocaleService.t('free')
                : '${LocaleService.t('qar')} ${_deliveryCost.toStringAsFixed(2)}',
            valueColor: _deliveryCost == 0
                ? const Color(0xFF2ECC71)
                : null,
          ),
          if (_appliedCoupon != null) ...[
            const SizedBox(height: 6),
            _SummaryRow(
              label: LocaleService.t('discount'),
              value:
                  '- ${LocaleService.t('qar')} ${_discountAmount.toStringAsFixed(2)}',
              valueColor: const Color(0xFF2ECC71),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          _SummaryRow(
            label: LocaleService.t('total'),
            value:
                '${LocaleService.t('qar')} ${_total.toStringAsFixed(2)}',
            isBold: true,
          ),
          if (_deliveryCost > 0 && _subtotal < 200) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${LocaleService.t('qar')} ${(200 - _subtotal).toStringAsFixed(2)} ${LocaleService.t('free_delivery_hint')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (!AuthService.isLoggedIn) {
                  Navigator.pushNamed(context, '/login');
                  return;
                }
                Navigator.pushNamed(context, '/checkout');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    LocaleService.t('checkout'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${LocaleService.t('qar')} ${_total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.imageUrl,
  });

  final String itemId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16)),
            child: SizedBox(
              width: 88,
              height: 88,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${LocaleService.t('qar')} ${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                      _QuantityControl(
                        quantity: quantity,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => productImagePlaceholder();
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                quantity == 1
                    ? Icons.delete_outline
                    : Icons.remove,
                size: 16,
                color: quantity == 1
                    ? const Color(0xFFFF6B6B)
                    : AppColors.secondary,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onIncrement,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.add,
                  size: 16, color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight:
                isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 13,
            fontWeight:
                isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ??
                (isBold
                    ? AppColors.secondary
                    : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
