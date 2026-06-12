import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/api_client.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _loading = true;
  bool _cancelling = false;
  String? _error;
  Map<String, dynamic>? _orderData;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await CustomerService.getOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _orderData = res['data'] as Map<String, dynamic>? ?? res;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : LocaleService.t('error_generic');
          _loading = false;
        });
      }
    }
  }

  String get _status => _orderData?['status']?.toString() ?? '';
  bool get _canCancel => _status == 'pending' || _status == 'confirmed';

  int _statusToStep(String status) {
    switch (status) {
      case 'pending':
      case 'confirmed':
        return 1;
      case 'processing':
        return 2;
      case 'out_for_delivery':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade600;
      case 'confirmed':
        return Colors.blue.shade600;
      case 'processing':
        return Colors.purple.shade600;
      case 'out_for_delivery':
        return Colors.teal.shade600;
      case 'delivered':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _cancelOrder() async {
    setState(() => _cancelling = true);
    try {
      await CustomerService.cancelOrder(widget.orderId);
      await _loadOrder();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : LocaleService.t('error_generic'))),
        );
        setState(() => _cancelling = false);
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocaleService.t('cancel_order')),
        content: Text(LocaleService.t('cancel_confirm_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleService.t('back')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelOrder();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text(LocaleService.t('confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderNum = _orderData?['order_number']?.toString() ?? widget.orderId;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              LocaleService.t('order_detail'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (!_loading && _orderData != null)
              Text(
                '#$orderNum',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            child: Text(LocaleService.t('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final order = _orderData!;
    final status = order['status']?.toString() ?? '';
    final items = (order['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final address = order['address'] as Map<String, dynamic>?;
    final paymentMethod = order['payment_method']?.toString() ?? 'cash_on_delivery';
    final subtotal = (order['subtotal'] as num?)?.toDouble() ?? (order['total'] as num?)?.toDouble() ?? 0;
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final delivery = (order['delivery_fee'] as num?)?.toDouble() ?? (total - subtotal > 0 ? total - subtotal : 0);
    final step = _statusToStep(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionCard(
            title: LocaleService.t('order_tracking'),
            child: _buildTrackingTimeline(step, status),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: LocaleService.t('items'),
            child: Column(
              children: items.isEmpty
                  ? [
                      const Text(
                        'No items',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ]
                  : items.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      final product = item['product'] as Map<String, dynamic>?;
                      final name = product?['name']?.toString() ?? 'Product';
                      final price = (product?['price'] as num?)?.toDouble() ?? 0;
                      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                      return Column(
                        children: [
                          if (i > 0) const Divider(color: AppColors.divider, height: 16),
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: _productThumb(product),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                    Text('${LocaleService.t('qty')}: $qty', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text(
                                '${LocaleService.t('qar')} ${(price * qty).toStringAsFixed(2)}',
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      );
                    }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (address != null)
            _sectionCard(
              title: LocaleService.t('delivery_address'),
              child: _buildAddressCard(address),
            ),
          const SizedBox(height: 16),
          _sectionCard(
            title: LocaleService.t('payment_method'),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, color: AppColors.secondary, size: 20),
                const SizedBox(width: 10),
                Text(
                  _paymentLabel(paymentMethod),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: LocaleService.t('order_summary'),
            child: Column(
              children: [
                _summaryRow(LocaleService.t('subtotal'), '${LocaleService.t('qar')} ${subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _summaryRow(
                  LocaleService.t('delivery'),
                  delivery == 0 ? LocaleService.t('free') : '${LocaleService.t('qar')} ${delivery.toStringAsFixed(2)}',
                ),
                const Divider(color: AppColors.divider, height: 20),
                _summaryRow(
                  LocaleService.t('total'),
                  '${LocaleService.t('qar')} ${total.toStringAsFixed(2)}',
                  isBold: true,
                  valueColor: AppColors.secondary,
                ),
              ],
            ),
          ),
          if (_canCancel) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _cancelling ? null : _showCancelDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _cancelling
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(LocaleService.t('cancel_order'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> addr) {
    final firstName = addr['first_name']?.toString() ?? '';
    final lastName = addr['last_name']?.toString() ?? '';
    final line1 = addr['address_line1']?.toString() ?? '';
    final line2 = addr['address_line2']?.toString() ?? '';
    final city = addr['city']?.toString() ?? '';
    final phone = addr['phone']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$firstName $lastName', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        if (line1.isNotEmpty) Text(line1, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        if (line2.isNotEmpty) Text(line2, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        if (city.isNotEmpty) Text(city, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        if (phone.isNotEmpty) Text(phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildTrackingTimeline(int currentStep, String status) {
    final isCancelled = status == 'cancelled';
    final steps = [
      LocaleService.t('order_placed_step'),
      LocaleService.t('processing_step'),
      LocaleService.t('out_for_delivery_step'),
      LocaleService.t('delivered_step'),
    ];

    if (isCancelled) {
      return Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
            child: Icon(Icons.close, color: Colors.red.shade600, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            LocaleService.t('cancelled'),
            style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Column(
      children: List.generate(steps.length, (i) {
        final stepNum = i + 1;
        final isDone = currentStep >= stepNum;
        final isActive = currentStep == stepNum;
        final isLast = i == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.secondary : AppColors.divider,
                        shape: BoxShape.circle,
                      ),
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Center(
                              child: Text(
                                '$stepNum',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isDone ? AppColors.secondary : AppColors.divider,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 4),
                  child: Text(
                    steps[i],
                    style: TextStyle(
                      color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _productThumb(Map<String, dynamic>? product) {
    final raw = product?['images'] as List<dynamic>? ?? [];
    String? url;
    if (raw.isNotEmpty) {
      final first = raw.first;
      if (first is String && first.isNotEmpty) url = first;
      else if (first is Map) url = first['url']?.toString();
    }
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(url, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary, size: 20)),
      );
    }
    return const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary, size: 20);
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'cash_on_delivery':
        return LocaleService.t('cash_on_delivery');
      case 'credit_card':
        return LocaleService.t('credit_card');
      default:
        return method;
    }
  }
}
