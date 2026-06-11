import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supplier_service.dart';
import '../../../core/services/api_client.dart';

class SupplierInventoryScreen extends StatefulWidget {
  const SupplierInventoryScreen({super.key});

  @override
  State<SupplierInventoryScreen> createState() => _SupplierInventoryScreenState();
}

class _SupplierInventoryScreenState extends State<SupplierInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<_InventoryItem>? _items;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await SupplierService.getInventory(page: 1, search: _searchQuery.isEmpty ? null : _searchQuery);
      if (!mounted) return;
      final data = res['data'] as List<dynamic>? ?? [];
      setState(() {
        _items = data.map((r) {
          final m = r as Map<String, dynamic>;
          return _InventoryItem(
            id: m['id']?.toString() ?? '',
            name: m['name']?.toString() ?? '',
            sku: m['sku']?.toString() ?? '',
            quantity: int.tryParse(m['available']?.toString() ?? '0') ?? 0,
            reorderPoint: int.tryParse(m['reorder_point']?.toString() ?? '0') ?? 0,
            reserved: int.tryParse(m['reserved']?.toString() ?? '0') ?? 0,
            price: double.tryParse(m['price']?.toString() ?? '0') ?? 0,
            isActive: m['is_active'] == true,
          );
        }).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load inventory. Pull down to retry.'; _loading = false; });
    }
  }

  List<_InventoryItem> _filtered(String filter) {
    var list = (_items ?? []).where((i) =>
        i.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        i.sku.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return switch (filter) {
      'low' => list.where((i) => i.quantity > 0 && i.quantity <= i.reorderPoint).toList(),
      'out' => list.where((i) => i.quantity <= 0).toList(),
      _ => list,
    };
  }

  int get _lowCount => (_items ?? []).where((i) => i.quantity > 0 && i.quantity <= i.reorderPoint).length;
  int get _outCount => (_items ?? []).where((i) => i.quantity <= 0).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Inventory',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.file_download_outlined), onPressed: () {}, tooltip: 'Export CSV'),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          tabs: [
            const Tab(text: 'All'),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Low Stock'),
                if (_lowCount > 0) ...[const SizedBox(width: 6), _badge(_lowCount, Colors.orange)],
              ]),
            ),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Out of Stock'),
                if (_outCount > 0) ...[const SizedBox(width: 6), _badge(_outCount, Colors.red)],
              ]),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    _buildSearchBar(),
                    _buildSummaryRow(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchData,
                        child: TabBarView(
                          controller: _tabCtrl,
                          children: [_buildList('all'), _buildList('low'), _buildList('out')],
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBulkUpdateSheet(),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.upload_outlined, color: Colors.white),
        label: const Text('Bulk Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
        ]),
      ),
    );
  }

  Widget _badge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
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
                  onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final total = _items?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _SummaryStat('Total SKUs', '$total', AppColors.secondary),
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
            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(filter == 'out' ? 'No out-of-stock items' : 'No items found',
                style: const TextStyle(color: AppColors.textSecondary)),
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
    final notesCtrl = TextEditingController();
    String txnType = 'restock';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update Stock — ${item.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Current stock: ${item.quantity} units',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              const Text('Transaction Type',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['restock', 'adjustment', 'damage', 'return'].map((t) => ChoiceChip(
                  label: Text(t[0].toUpperCase() + t.substring(1)),
                  selected: txnType == t,
                  selectedColor: AppColors.secondary.withOpacity(0.15),
                  onSelected: (_) => setModal(() => txnType = t),
                  labelStyle: TextStyle(
                    color: txnType == t ? AppColors.secondary : AppColors.textSecondary,
                    fontWeight: txnType == t ? FontWeight.w600 : FontWeight.normal,
                  ),
                )).toList(),
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
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
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
                  onPressed: () async {
                    final qty = int.tryParse(qtyCtrl.text) ?? 0;
                    if (qty == 0) return;
                    Navigator.pop(ctx);
                    try {
                      await SupplierService.adjustInventory(item.id, qty, notesCtrl.text.trim().isEmpty ? txnType : notesCtrl.text.trim());
                      await _fetchData();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Stock updated: ${item.name}'), behavior: SnackBarBehavior.floating),
                      );
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update stock'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Update', style: TextStyle(color: Colors.white)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bulk Inventory Update',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Upload a CSV file with SKU and quantity columns to update multiple products at once.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            _BulkOption(Icons.file_upload_outlined, 'Upload CSV File', 'Supports SKU, quantity, reorder_point columns', () {}),
            const SizedBox(height: 12),
            _BulkOption(Icons.file_download_outlined, 'Download Template', 'Get the CSV template to fill in', () {}),
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
  const _InventoryCard({required this.item, required this.onAdjust, required this.onToggle});

  Color get _stockColor {
    if (item.quantity <= 0) return Colors.red;
    if (item.quantity <= item.reorderPoint) return Colors.orange;
    return const Color(0xFF2E7D32);
  }

  String get _stockLabel {
    if (item.quantity <= 0) return 'Out of Stock';
    if (item.quantity <= item.reorderPoint) return 'Low Stock';
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    final maxQty = item.reorderPoint * 3;
    final pct = maxQty > 0 ? item.quantity / maxQty : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.quantity <= 0
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
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${item.sku} · QAR ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Switch(value: item.isActive, onChanged: (_) => onToggle(), activeColor: AppColors.secondary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatBox('Available', '${item.quantity}', _stockColor),
              const SizedBox(width: 8),
              _StatBox('Reorder At', '${item.reorderPoint}', AppColors.textSecondary),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _stockColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(_stockLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _stockColor)),
              ),
              TextButton.icon(
                onPressed: onAdjust,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Adjust Stock'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
        width: 44, height: 44,
        decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.secondary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _InventoryItem {
  final String id, name, sku;
  int quantity;
  final int reorderPoint;
  final int reserved;
  final double price;
  bool isActive;

  _InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.reorderPoint,
    required this.reserved,
    required this.price,
    required this.isActive,
  });
}
