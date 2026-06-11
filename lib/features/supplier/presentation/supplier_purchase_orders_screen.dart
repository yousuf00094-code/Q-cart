import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supplier_service.dart';
import '../../../core/services/api_client.dart';

class SupplierPurchaseOrdersScreen extends StatefulWidget {
  const SupplierPurchaseOrdersScreen({super.key});

  @override
  State<SupplierPurchaseOrdersScreen> createState() =>
      _SupplierPurchaseOrdersScreenState();
}

class _SupplierPurchaseOrdersScreenState
    extends State<SupplierPurchaseOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<_PurchaseOrder>? _orders;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await SupplierService.getOrders(page: 1);
      final data = res['data'] as List<dynamic>? ?? [];
      final orders = data.map((raw) {
        final m = raw as Map<String, dynamic>;
        final itemCount = m['item_count'];
        final countNum = itemCount is int ? itemCount : int.tryParse(itemCount?.toString() ?? '0') ?? 0;
        final total = m['total'];
        final totalStr = total is num
            ? 'QAR ${total.toStringAsFixed(2)}'
            : 'QAR ${total ?? '0.00'}';
        return _PurchaseOrder(
          uuid: m['id']?.toString() ?? '',
          id: m['order_number']?.toString() ?? m['id']?.toString() ?? '',
          buyer: m['customer_name']?.toString() ?? '',
          itemCount: '$countNum item${countNum != 1 ? 's' : ''}',
          total: totalStr,
          status: m['status']?.toString() ?? '',
          date: _formatDate(m['created_at']?.toString() ?? ''),
          items: const [],
        );
      }).toList();
      if (mounted) {
        setState(() {
          _orders = orders;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load orders. Please try again.'; _loading = false; });
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso) ?? DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  List<_PurchaseOrder> _filtered(String filter) {
    final src = _orders ?? [];
    var list = src
        .where((o) =>
            o.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            o.buyer.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    return switch (filter) {
      'pending' => list.where((o) => o.status == 'pending' || o.status == 'confirmed').toList(),
      'processing' => list.where((o) => o.status == 'processing' || o.status == 'out_for_delivery').toList(),
      'done' => list.where((o) => o.status == 'delivered' || o.status == 'cancelled').toList(),
      _ => list,
    };
  }

  int get _pendingCount => (_orders ?? []).where((o) => o.status == 'pending' || o.status == 'confirmed').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Purchase Orders',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          tabs: [
            const Tab(text: 'All'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  if (_pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$_pendingCount',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Processing'),
            const Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _buildList('all'),
                            _buildList('pending'),
                            _buildList('processing'),
                            _buildList('done'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search order ID or buyer…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
        ),
      ),
    );
  }

  Widget _buildList(String filter) {
    final list = _filtered(filter);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('No items yet.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: list.length,
      itemBuilder: (_, i) => _OrderCard(
        order: list[i],
        onAccept: (list[i].status == 'pending' || list[i].status == 'confirmed')
            ? () => _acceptOrder(list[i])
            : null,
        onShip: list[i].status == 'processing'
            ? () => _showShipSheet(list[i])
            : null,
        onView: () => _showOrderDetail(list[i]),
      ),
    );
  }

  Future<void> _acceptOrder(_PurchaseOrder order) async {
    try {
      await SupplierService.updateOrderStatus(order.uuid, 'processing');
      if (!mounted) return;
      setState(() => order.status = 'processing');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept order. Please retry.')),
      );
    }
  }

  void _showShipSheet(_PurchaseOrder order) {
    final trackingCtrl = TextEditingController();
    String selectedCarrier = 'aramex';
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ship Order ${order.id}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCarrier,
                decoration: const InputDecoration(
                    labelText: 'Carrier',
                    prefixIcon: Icon(Icons.local_shipping_outlined)),
                items: ['aramex', 'dhl', 'q_cart_fleet']
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.toUpperCase().replaceAll('_', ' '))))
                    .toList(),
                onChanged: (v) => setSheet(() => selectedCarrier = v!),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: trackingCtrl,
                decoration: const InputDecoration(
                    labelText: 'Tracking Number',
                    prefixIcon: Icon(Icons.pin_outlined)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setSheet(() => saving = true);
                          try {
                            await Future.wait([
                              SupplierService.createShipment({
                                'order_id': order.uuid,
                                'carrier': selectedCarrier,
                                'tracking_number': trackingCtrl.text.trim(),
                              }),
                              SupplierService.updateOrderStatus(
                                  order.uuid, 'out_for_delivery'),
                            ]);
                            if (!mounted) return;
                            setState(() => order.status = 'out_for_delivery');
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${order.id} marked as shipped'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (_) {
                            setSheet(() => saving = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Failed to create shipment. Please retry.')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm Shipment',
                          style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetail(_PurchaseOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.id,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  _StatusChip(order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(order.date,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const Divider(height: 24),
              const Text('Items',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              if (order.items.isEmpty)
                Text(order.itemCount,
                    style: const TextStyle(color: AppColors.textSecondary))
              else
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 6, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(item,
                              style: const TextStyle(
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 16)),
                  Text(order.total,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                          fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final _PurchaseOrder order;
  final VoidCallback? onAccept;
  final VoidCallback? onShip;
  final VoidCallback onView;
  const _OrderCard(
      {required this.order,
      this.onAccept,
      this.onShip,
      required this.onView});

  @override
  Widget build(BuildContext context) {
    final isPending = order.status == 'pending' || order.status == 'confirmed';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? AppColors.secondary.withOpacity(0.4)
              : AppColors.divider,
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.id,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 15)),
                  _StatusChip(order.status),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(order.date,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  const Icon(Icons.shopping_bag_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(order.itemCount,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.total,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary)),
                  Row(
                    children: [
                      if (onAccept != null)
                        ElevatedButton(
                          onPressed: onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Accept',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      if (onShip != null)
                        ElevatedButton(
                          onPressed: onShip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Ship Now',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  Color get _color => switch (status) {
        'pending' => AppColors.secondary,
        'confirmed' => AppColors.secondary,
        'processing' => const Color(0xFFF57F17),
        'out_for_delivery' => const Color(0xFF1565C0),
        'delivered' => const Color(0xFF2E7D32),
        'cancelled' => Colors.red,
        _ => AppColors.textSecondary,
      };

  String get _label => switch (status) {
        'pending' => 'Pending',
        'confirmed' => 'Confirmed',
        'processing' => 'Processing',
        'out_for_delivery' => 'Out for Delivery',
        'delivered' => 'Delivered',
        'cancelled' => 'Cancelled',
        _ => status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : '',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(_label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _color)),
    );
  }
}

class _PurchaseOrder {
  final String uuid, id, buyer, itemCount, total, date;
  String status;
  final List<String> items;

  _PurchaseOrder({
    required this.uuid,
    required this.id,
    required this.buyer,
    required this.itemCount,
    required this.total,
    required this.status,
    required this.date,
    required this.items,
  });
}
