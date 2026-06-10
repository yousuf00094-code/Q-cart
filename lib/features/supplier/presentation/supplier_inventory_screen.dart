import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SupplierInventoryScreen extends StatefulWidget {
  const SupplierInventoryScreen({super.key});

  @override
  State<SupplierInventoryScreen> createState() =>
      _SupplierInventoryScreenState();
}

class _SupplierInventoryScreenState extends State<SupplierInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<_InventoryItem> _items = [
    _InventoryItem('Wireless Earbuds Pro', 'SKU-001', 142, 20, 10, 149.00, true),
    _InventoryItem('USB-C Hub 7-in-1', 'SKU-002', 5, 15, 10, 89.00, true),
    _InventoryItem('Laptop Stand Aluminium', 'SKU-003', 0, 8, 5, 129.00, true),
    _InventoryItem('Mechanical Keyboard', 'SKU-004', 38, 10, 8, 249.00, true),
    _InventoryItem('Webcam 1080p', 'SKU-005', 12, 12, 10, 199.00, false),
    _InventoryItem('Mouse Pad XL', 'SKU-006', 3, 5, 5, 45.00, true),
    _InventoryItem('Phone Stand Adjustable', 'SKU-007', 67, 10, 10, 35.00, true),
    _InventoryItem('HDMI Cable 2m', 'SKU-008', 89, 20, 15, 25.00, true),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_InventoryItem> _filtered(String filter) {
    var list = _items
        .where((i) =>
            i.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            i.sku.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    return switch (filter) {
      'low' => list.where((i) => i.quantity > 0 && i.quantity <= i.reorderPoint).toList(),
      'out' => list.where((i) => i.quantity == 0).toList(),
      _ => list,
    };
  }

  int get _lowCount =>
      _items.where((i) => i.quantity > 0 && i.quantity <= i.reorderPoint).length;
  int get _outCount => _items.where((i) => i.quantity == 0).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Inventory',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {},
            tooltip: 'Export CSV',
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
                  const Text('Low Stock'),
                  if (_lowCount > 0) ...[
                    const SizedBox(width: 6),
                    _badge(_lowCount, Colors.orange),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Out of Stock'),
                  if (_outCount > 0) ...[
                    const SizedBox(width: 6),
                    _badge(_outCount, Colors.red),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSummaryRow(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList('all'),
                _buildList('low'),
                _buildList('out'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBulkUpdateSheet(),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.upload_outlined, color: Colors.white),
        label: const Text('Bulk Update',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _badge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$count',
          style: const TextStyle(
              fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search products or SKU…',
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

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _SummaryStat('Total SKUs', '${_items.length}', AppColors.secondary),
          const SizedBox(width: 10),
          _SummaryStat('Low Stock', '$_lowCount', Colors.orange),
          const SizedBox(width: 10),
          _SummaryStat('Out of Stock', '$_outCount', Colors.red),
        ],
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
            Icon(Icons.inventory_2_outlined,
                size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              filter == 'out' ? 'No out-of-stock items' : 'No items found',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: list.length,
      itemBuilder: (_, i) => _InventoryCard(
        item: list[i],
        onAdjust: () => _showAdjustSheet(list[i]),
        onToggle: () => setState(() => list[i].isActive = !list[i].isActive),
      ),
    );
  }

  void _showAdjustSheet(_InventoryItem item) {
    final qtyCtrl = TextEditingController();
    String txnType = 'restock';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update Stock — ${item.name}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Current stock: ${item.quantity} units',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              const Text('Transaction Type',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['restock', 'adjustment', 'damage', 'return'].map(
                  (t) => ChoiceChip(
                    label: Text(t[0].toUpperCase() + t.substring(1)),
                    selected: txnType == t,
                    selectedColor: AppColors.secondary.withOpacity(0.15),
                    onSelected: (_) => setModalState(() => txnType = t),
                    labelStyle: TextStyle(
                      color: txnType == t
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                      fontWeight: txnType == t
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: txnType == 'damage' || txnType == 'adjustment'
                      ? 'Quantity (negative to reduce)'
                      : 'Quantity to Add',
                  prefixIcon: const Icon(Icons.numbers_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final qty = int.tryParse(qtyCtrl.text) ?? 0;
                    setState(() {
                      item.quantity = (item.quantity + qty).clamp(0, 99999);
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Stock updated: ${item.name} → ${item.quantity} units'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Update',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBulkUpdateSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bulk Inventory Update',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
                'Upload a CSV file with SKU and quantity columns to update multiple products at once.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            _BulkOption(Icons.file_upload_outlined, 'Upload CSV File',
                'Supports SKU, quantity, reorder_point columns', () {}),
            const SizedBox(height: 12),
            _BulkOption(Icons.file_download_outlined, 'Download Template',
                'Get the CSV template to fill in', () {}),
          ],
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final _InventoryItem item;
  final VoidCallback onAdjust;
  final VoidCallback onToggle;
  const _InventoryCard(
      {required this.item, required this.onAdjust, required this.onToggle});

  Color get _stockColor {
    if (item.quantity == 0) return Colors.red;
    if (item.quantity <= item.reorderPoint) return Colors.orange;
    return const Color(0xFF2E7D32);
  }

  String get _stockLabel {
    if (item.quantity == 0) return 'Out of Stock';
    if (item.quantity <= item.reorderPoint) return 'Low Stock';
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    final pct = item.quantity / (item.reorderPoint * 3);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.quantity == 0
              ? Colors.red.withOpacity(0.3)
              : item.quantity <= item.reorderPoint
                  ? Colors.orange.withOpacity(0.3)
                  : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${item.sku} · QAR ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: item.isActive,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatBox('Available', '${item.quantity}', _stockColor),
              const SizedBox(width: 8),
              _StatBox('Reorder At', '${item.reorderPoint}',
                  AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: _stockColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_stockColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _stockColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_stockLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _stockColor)),
              ),
              TextButton.icon(
                onPressed: onAdjust,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Adjust Stock'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _BulkOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _BulkOption(this.icon, this.title, this.subtitle, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.secondary),
      ),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _InventoryItem {
  final String name, sku;
  int quantity;
  final int reorderPoint;
  final int reserved;
  final double price;
  bool isActive;

  _InventoryItem(this.name, this.sku, this.quantity, this.reorderPoint,
      this.reserved, this.price, this.isActive);
}
