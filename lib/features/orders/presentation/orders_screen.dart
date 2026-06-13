import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/parse_num.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _historyOrders = [];

  final Set<String> _expandedTracking = {};
  final Set<String> _cancellingIds = {};
  final Set<String> _reorderingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await CustomerService.getOrders();
      final data = res['data'] as List<dynamic>? ?? [];
      final orders = data.cast<Map<String, dynamic>>();
      const activeStatuses = {'pending', 'confirmed', 'processing', 'out_for_delivery'};
      if (mounted) {
        setState(() {
          _activeOrders = orders.where((o) => activeStatuses.contains(o['status']?.toString())).toList();
          _historyOrders = orders.where((o) => !activeStatuses.contains(o['status']?.toString())).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : LocaleService.t('error_generic');
          _loading = false;
        });
      }
    }
  }

  Future<void> _cancelOrder(String id) async {
    setState(() => _cancellingIds.add(id));
    try {
      await CustomerService.cancelOrder(id);
      await _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : LocaleService.t('error_generic'))),
        );
      }
    } finally {
      if (mounted) setState(() => _cancellingIds.remove(id));
    }
  }

  Future<void> _reorder(Map<String, dynamic> order) async {
    final id = order['id']?.toString() ?? '';
    setState(() => _reorderingIds.add(id));
    try {
      final detail = await CustomerService.getOrder(id);
      final orderData = detail['data'] as Map<String, dynamic>? ?? detail;
      final items = orderData['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final product = item['product'] as Map<String, dynamic>?;
        final productId = product?['id']?.toString();
        final qty = parseInt(item['quantity'], 1);
        if (productId != null) {
          await CartService.addItem(productId, qty);
        }
      }
      if (mounted) {
        Navigator.pushNamed(context, '/cart');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : LocaleService.t('error_generic'))),
        );
      }
    } finally {
      if (mounted) setState(() => _reorderingIds.remove(id));
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          LocaleService.t('my_orders'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          tabs: [
            Tab(text: LocaleService.t('active')),
            Tab(text: LocaleService.t('history')),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      color: AppColors.secondary,
                      onRefresh: _loadOrders,
                      child: _buildActiveTab(),
                    ),
                    RefreshIndicator(
                      color: AppColors.secondary,
                      onRefresh: _loadOrders,
                      child: _buildHistoryTab(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(LocaleService.t('error_generic'), style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrders,
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

  Widget _buildActiveTab() {
    if (_activeOrders.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeOrders.length,
      itemBuilder: (_, i) => _buildActiveOrderCard(_activeOrders[i]),
    );
  }

  Widget _buildHistoryTab() {
    if (_historyOrders.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyOrders.length,
      itemBuilder: (_, i) => _buildHistoryOrderCard(_historyOrders[i]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.divider),
          const SizedBox(height: 16),
          Text(
            LocaleService.t('no_orders'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderCard(Map<String, dynamic> order) {
    final id = order['id']?.toString() ?? '';
    final orderNum = order['order_number']?.toString() ?? id;
    final status = order['status']?.toString() ?? '';
    final total = order['total'];
    final totalStr = total is num ? total.toStringAsFixed(2) : (total?.toString() ?? '0.00');
    final itemCount = parseInt(order['item_count']);
    final createdAt = order['created_at']?.toString() ?? '';
    final dateStr = _formatDate(createdAt);
    final canCancel = status == 'pending' || status == 'confirmed';
    final isExpanded = _expandedTracking.contains(id);
    final isCancelling = _cancellingIds.contains(id);
    final step = _statusToStep(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#$orderNum',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    _statusChip(status),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.inventory_2_outlined, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '$itemCount ${LocaleService.t(itemCount == 1 ? 'item' : 'items')}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QAR $totalStr',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        if (canCancel)
                          TextButton(
                            onPressed: isCancelling ? null : () => _showCancelDialog(id),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Text(LocaleService.t('cancel_order'), style: const TextStyle(fontSize: 13)),
                          ),
                        TextButton(
                          onPressed: () => setState(() {
                            if (isExpanded) {
                              _expandedTracking.remove(id);
                            } else {
                              _expandedTracking.add(id);
                            }
                          }),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(LocaleService.t('track'), style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _buildTrackingTimeline(step, status),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryOrderCard(Map<String, dynamic> order) {
    final id = order['id']?.toString() ?? '';
    final orderNum = order['order_number']?.toString() ?? id;
    final status = order['status']?.toString() ?? '';
    final total = order['total'];
    final totalStr = total is num ? total.toStringAsFixed(2) : (total?.toString() ?? '0.00');
    final itemCount = parseInt(order['item_count']);
    final createdAt = order['created_at']?.toString() ?? '';
    final dateStr = _formatDate(createdAt);
    final isDelivered = status == 'delivered';
    final isReordering = _reorderingIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#$orderNum',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 12),
              const Icon(Icons.inventory_2_outlined, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '$itemCount ${LocaleService.t(itemCount == 1 ? 'item' : 'items')}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QAR $totalStr',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/order-detail', arguments: id),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Text(LocaleService.t('order_detail'), style: const TextStyle(fontSize: 13)),
                  ),
                  if (isDelivered)
                    TextButton(
                      onPressed: isReordering ? null : () => _reorder(order),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: isReordering
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                            )
                          : Text(LocaleService.t('reorder'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        LocaleService.t(status.isNotEmpty ? status : 'pending'),
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
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
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
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

  void _showCancelDialog(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocaleService.t('cancel_order')),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleService.t('back')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelOrder(id);
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

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
