import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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

  final List<_PurchaseOrder> _orders = [
    _PurchaseOrder('PO-4201', 'Q Cart Warehouse', '2 items', 'QAR 245.00',
        'new', '10 Jun 2026', ['Wireless Earbuds Pro ×1', 'USB-C Hub ×1']),
    _PurchaseOrder('PO-4198', 'Q Cart Warehouse', '1 item', 'QAR 89.50',
        'processing', '9 Jun 2026', ['USB-C Hub 7-in-1 ×1']),
    _PurchaseOrder('PO-4185', 'Q Cart Warehouse', '3 items', 'QAR 512.00',
        'shipped', '8 Jun 2026',
        ['Mechanical Keyboard ×2', 'Webcam 1080p ×1']),
    _PurchaseOrder('PO-4172', 'Q Cart Warehouse', '1 item', 'QAR 67.00',
        'delivered', '7 Jun 2026', ['Mouse Pad XL ×2']),
    _PurchaseOrder('PO-4160', 'Q Cart Warehouse', '2 items', 'QAR 198.75',
        'delivered', '6 Jun 2026',
        ['Phone Stand Adjustable ×3', 'HDMI Cable ×1']),
    _PurchaseOrder('PO-4145', 'Q Cart Warehouse', '1 item', 'QAR 149.00',
        'cancelled', '5 Jun 2026', ['Wireless Earbuds Pro ×1']),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_PurchaseOrder> _filtered(String filter) {
    var list = _orders
        .where((o) =>
            o.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            o.buyer.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    return switch (filter) {
      'new' => list.where((o) => o.status == 'new').toList(),
      'active' => list
          .where((o) =>
              o.status == 'processing' || o.status == 'shipped')
          .toList(),
      'done' => list
          .where((o) =>
              o.status == 'delivered' || o.status == 'cancelled')
          .toList(),
      _ => list,
    };
  }

  int get _newCount => _orders.where((o) => o.status == 'new').length;

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
                  const Text('New'),
                  if (_newCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$_newCount',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Active'),
            const Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList('all'),
                _buildList('new'),
                _buildList('active'),
                _buildList('done'),
              ],
            ),
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
            const Text('No orders found',
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
        onAccept: list[i].status == 'new'
            ? () => setState(() => list[i].status = 'processing')
            : null,
        onShip: list[i].status == 'processing'
            ? () => _showShipSheet(list[i])
            : null,
        onView: () => _showOrderDetail(list[i]),
      ),
    );
  }

  void _showShipSheet(_PurchaseOrder order) {
    final trackingCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
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
              value: 'aramex',
              decoration: const InputDecoration(
                  labelText: 'Carrier',
                  prefixIcon: Icon(Icons.local_shipping_outlined)),
              items: ['aramex', 'dhl', 'q_cart_fleet']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase().replaceAll('_', ' '))))
                  .toList(),
              onChanged: (_) {},
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
                onPressed: () {
                  setState(() => order.status = 'shipped');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${order.id} marked as shipped'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm Shipment',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: order.status == 'new'
              ? AppColors.secondary.withOpacity(0.4)
              : AppColors.divider,
          width: order.status == 'new' ? 1.5 : 1,
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
        'new' => AppColors.secondary,
        'processing' => const Color(0xFFF57F17),
        'shipped' => const Color(0xFF1565C0),
        'delivered' => const Color(0xFF2E7D32),
        'cancelled' => Colors.red,
        _ => AppColors.textSecondary,
      };

  String get _label => status[0].toUpperCase() + status.substring(1);

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
  final String id, buyer, itemCount, total, date;
  String status;
  final List<String> items;

  _PurchaseOrder(this.id, this.buyer, this.itemCount, this.total, this.status,
      this.date, this.items);
}
