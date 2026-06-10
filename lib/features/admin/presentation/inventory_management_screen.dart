import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  String _query = '';

  static final List<_InventoryItem> _items = [
    _InventoryItem(sku: 'GR-DATES-500', name: 'Organic Dates 500g', category: 'Groceries',
        qty: 84, reserved: 6, reorderPoint: 20, reorderQty: 200, supplier: 'Al Meera'),
    _InventoryItem(sku: 'GR-SAFFRON-5', name: 'Saffron Pack 5g', category: 'Groceries',
        qty: 8, reserved: 2, reorderPoint: 10, reorderQty: 50, supplier: 'Qatar Spices Co.'),
    _InventoryItem(sku: 'DA-CAMEL-1L', name: 'Camel Milk 1L', category: 'Dairy',
        qty: 42, reserved: 15, reorderPoint: 30, reorderQty: 100, supplier: 'Gulf Fresh Dairy'),
    _InventoryItem(sku: 'EL-IPHN-15', name: 'iPhone 15 128GB', category: 'Electronics',
        qty: 12, reserved: 3, reorderPoint: 5, reorderQty: 20, supplier: 'TechSupply ME'),
    _InventoryItem(sku: 'GR-OLIVE-1L', name: 'Extra Virgin Olive Oil 1L', category: 'Groceries',
        qty: 3, reserved: 1, reorderPoint: 15, reorderQty: 80, supplier: 'Al Meera'),
    _InventoryItem(sku: 'GR-HONEY-500', name: 'Sidr Honey 500g', category: 'Groceries',
        qty: 55, reserved: 4, reorderPoint: 20, reorderQty: 100, supplier: 'Desert Farms'),
    _InventoryItem(sku: 'BE-ROSEWATER', name: 'Rose Water 250ml', category: 'Beauty',
        qty: 0, reserved: 0, reorderPoint: 25, reorderQty: 60, supplier: 'Qatar Spices Co.'),
    _InventoryItem(sku: 'SP-YOGA-MAT', name: 'Premium Yoga Mat', category: 'Sports',
        qty: 18, reserved: 2, reorderPoint: 10, reorderQty: 30, supplier: 'TechSupply ME'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_InventoryItem> _filtered(_StockFilter filter) {
    return _items.where((i) {
      final matchQuery = _query.isEmpty ||
          i.name.toLowerCase().contains(_query.toLowerCase()) ||
          i.sku.toLowerCase().contains(_query.toLowerCase());
      final matchFilter = switch (filter) {
        _StockFilter.all      => true,
        _StockFilter.low      => i.available > 0 && i.available <= i.reorderPoint,
        _StockFilter.outOfStock => i.available == 0,
      };
      return matchQuery && matchFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final low = _items.where((i) => i.available > 0 && i.available <= i.reorderPoint).length;
    final oos = _items.where((i) => i.available == 0).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Inventory',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppColors.secondary),
            onPressed: () {},
            tooltip: 'Export CSV',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(3),
              tabs: [
                const Tab(text: 'All'),
                Tab(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Low Stock'),
                    if (low > 0) ...[
                      const SizedBox(width: 4),
                      _Badge('$low', const Color(0xFFF57C00)),
                    ],
                  ]),
                ),
                Tab(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Out of Stock'),
                    if (oos > 0) ...[
                      const SizedBox(width: 4),
                      _Badge('$oos', const Color(0xFFE53935)),
                    ],
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearch(),
          _buildStockSummary(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _InventoryList(items: _filtered(_StockFilter.all), onAdjust: (i) => _showAdjustSheet(context, i)),
                _InventoryList(items: _filtered(_StockFilter.low), onAdjust: (i) => _showAdjustSheet(context, i)),
                _InventoryList(items: _filtered(_StockFilter.outOfStock), onAdjust: (i) => _showAdjustSheet(context, i)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search by name or SKU…',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                  onPressed: () => setState(() { _searchCtrl.clear(); _query = ''; }),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStockSummary() {
    final totalUnits = _items.fold(0, (s, i) => s + i.available);
    final low = _items.where((i) => i.available > 0 && i.available <= i.reorderPoint).length;
    final oos = _items.where((i) => i.available == 0).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        Expanded(child: _SummaryBox('$totalUnits', 'Total Units', const Color(0xFFD4F5E9), const Color(0xFF388E3C))),
        const SizedBox(width: 10),
        Expanded(child: _SummaryBox('$low', 'Low Stock', const Color(0xFFFFF3E0), const Color(0xFFF57C00))),
        const SizedBox(width: 10),
        Expanded(child: _SummaryBox('$oos', 'Out of Stock', const Color(0xFFFFE8E8), const Color(0xFFE53935))),
      ]),
    );
  }

  void _showAdjustSheet(BuildContext context, _InventoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdjustStockSheet(item: item),
    );
  }
}

class _InventoryList extends StatelessWidget {
  const _InventoryList({required this.items, required this.onAdjust});
  final List<_InventoryItem> items;
  final void Function(_InventoryItem) onAdjust;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondary),
          SizedBox(height: 10),
          Text('No items found', style: TextStyle(color: AppColors.textSecondary)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _InventoryCard(item: items[i], onAdjust: onAdjust),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.onAdjust});
  final _InventoryItem item;
  final void Function(_InventoryItem) onAdjust;

  Color get _stockColor {
    if (item.available == 0) return const Color(0xFFE53935);
    if (item.available <= item.reorderPoint) return const Color(0xFFF57C00);
    return const Color(0xFF388E3C);
  }

  String get _stockLabel {
    if (item.available == 0) return 'Out of Stock';
    if (item.available <= item.reorderPoint) return 'Low Stock';
    return 'In Stock';
  }

  double get _stockRatio =>
      item.reorderPoint == 0 ? 1.0 : (item.available / (item.reorderPoint * 3)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${item.sku} · ${item.category}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: _stockColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_stockLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _stockColor)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Available', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text('${item.available}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _stockColor)),
          ])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Reserved', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text('${item.reserved}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Reorder at', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text('${item.reorderPoint}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ])),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _stockRatio,
            minHeight: 6,
            backgroundColor: AppColors.divider,
            color: _stockColor,
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Supplier: ${item.supplier}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          GestureDetector(
            onTap: () => onAdjust(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Adjust Stock',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _AdjustStockSheet extends StatefulWidget {
  const _AdjustStockSheet({required this.item});
  final _InventoryItem item;

  @override
  State<_AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends State<_AdjustStockSheet> {
  String _txnType = 'restock';
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  static const _types = ['restock', 'adjustment', 'return', 'damage'];

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Adjust Stock — ${widget.item.name}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Current available: ${widget.item.available} units',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          const Text('Transaction Type',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: _types.map((t) => GestureDetector(
            onTap: () => setState(() => _txnType = t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _txnType == t ? AppColors.secondary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _txnType == t ? AppColors.secondary : AppColors.divider),
              ),
              child: Text(t[0].toUpperCase() + t.substring(1),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _txnType == t ? Colors.white : AppColors.textSecondary)),
            ),
          )).toList()),
          const SizedBox(height: 14),
          TextField(
            controller: _qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantity'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Confirm Adjustment',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Small widgets ─────────────────────────────────────────────────────────

class _SummaryBox extends StatelessWidget {
  const _SummaryBox(this.value, this.label, this.bg, this.fg);
  final String value, label;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: fg.withOpacity(0.8))),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

enum _StockFilter { all, low, outOfStock }

class _InventoryItem {
  final String sku, name, category, supplier;
  final int qty, reserved, reorderPoint, reorderQty;

  int get available => qty - reserved;

  const _InventoryItem({
    required this.sku, required this.name, required this.category,
    required this.supplier, required this.qty, required this.reserved,
    required this.reorderPoint, required this.reorderQty,
  });
}
