import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<_CartItem> _items = [
    _CartItem(
      name: 'Organic Dates 500g',
      category: 'Groceries',
      price: 35.0,
      quantity: 2,
      gradientColors: [Color(0xFFD4F5E9), Color(0xFFA8E0D0)],
    ),
    _CartItem(
      name: 'Saffron Pack 5g',
      category: 'Groceries',
      price: 120.0,
      quantity: 1,
      gradientColors: [Color(0xFFDDD9F5), Color(0xFF9B97D6)],
    ),
    _CartItem(
      name: 'Camel Milk 1L',
      category: 'Dairy',
      price: 28.0,
      quantity: 3,
      gradientColors: [Color(0xFFFFE8D6), Color(0xFFFFBD96)],
    ),
  ];

  double get _subtotal =>
      _items.fold(0, (sum, item) => sum + item.price * item.quantity);

  double get _delivery => _subtotal > 200 ? 0 : 15.0;
  double get _discount => _subtotal * 0.05;
  double get _total => _subtotal + _delivery - _discount;

  void _remove(int index) {
    final removed = _items[index];
    setState(() => _items.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.name} removed'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primary,
          onPressed: () => setState(() => _items.insert(index, removed)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Cart',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_items.length} items',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _items.clear()),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _items.isEmpty ? _buildEmptyState() : _buildCartContent(context),
    );
  }

  Widget _buildEmptyState() {
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
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to start shopping',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Start Shopping',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _CartItemCard(
              item: _items[index],
              onRemove: () => _remove(index),
              onIncrement: () =>
                  setState(() => _items[index].quantity++),
              onDecrement: () {
                if (_items[index].quantity > 1) {
                  setState(() => _items[index].quantity--);
                } else {
                  _remove(index);
                }
              },
            ),
          ),
        ),
        _buildOrderSummary(context),
      ],
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const _SummaryRow(label: 'Subtotal', value: '', isHeader: true),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Subtotal', value: 'QAR ${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Delivery',
            value: _delivery == 0 ? 'Free' : 'QAR ${_delivery.toStringAsFixed(2)}',
            valueColor: _delivery == 0 ? const Color(0xFF2ECC71) : null,
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Discount (5%)',
            value: '- QAR ${_discount.toStringAsFixed(2)}',
            valueColor: const Color(0xFF2ECC71),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          _SummaryRow(
            label: 'Total',
            value: 'QAR ${_total.toStringAsFixed(2)}',
            isBold: true,
          ),
          if (_delivery > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Add QAR ${(200 - _subtotal).toStringAsFixed(0)} more for free delivery',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showCheckoutConfirmation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'QAR ${_total.toStringAsFixed(0)}',
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

  void _showCheckoutConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.check_circle_outline,
                size: 56, color: AppColors.secondary),
            const SizedBox(height: 12),
            const Text(
              'Order Confirmed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thank you for shopping with Q Cart',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Done',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onIncrement,
    required this.onDecrement,
  });

  final _CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.name),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8E8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: item.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16)),
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 36,
                color: Colors.white70,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'QAR ${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                        _QuantityControl(
                          quantity: item.quantity,
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
      ),
    );
  }
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
                quantity == 1 ? Icons.delete_outline : Icons.remove,
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
              child: Icon(Icons.add, size: 16, color: AppColors.secondary),
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
    this.isHeader = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    if (isHeader) {
      return const Text(
        'Order Summary',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ??
                (isBold ? AppColors.secondary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _CartItem {
  final String name;
  final String category;
  final double price;
  int quantity;
  final List<Color> gradientColors;

  _CartItem({
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    required this.gradientColors,
  });
}
