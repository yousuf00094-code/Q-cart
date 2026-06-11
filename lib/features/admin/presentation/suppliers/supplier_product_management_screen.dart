import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/services/api_client.dart';

class AdminSupplierProductManagementScreen extends StatefulWidget {
  const AdminSupplierProductManagementScreen({super.key});

  @override
  State<AdminSupplierProductManagementScreen> createState() =>
      _AdminSupplierProductManagementScreenState();
}

class _AdminSupplierProductManagementScreenState
    extends State<AdminSupplierProductManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _supplierFilter = 'all';

  List<_SupplierProduct>? _products;
  List<String> _supplierNames = ['all'];
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
      final res = await AdminService.getProducts(
        page: 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (!mounted) return;
      final data = res['data'] as List<dynamic>? ?? [];
      final products = data.map((r) {
        final m = r as Map<String, dynamic>;
        final isActive = m['is_active'] == true;
        final rawStatus = m['approval_status']?.toString();
        final approvalStatus = rawStatus ?? (isActive ? 'approved' : 'pending');
        return _SupplierProduct(
          id: m['id']?.toString() ?? '',
          name: m['name']?.toString() ?? '',
          supplier: m['supplier_name']?.toString() ?? m['supplier']?.toString() ?? '',
          category: m['category']?.toString() ?? '',
          price: double.tryParse(m['price']?.toString() ?? '0') ?? 0,
          stock: int.tryParse(m['stock_quantity']?.toString() ?? '0') ?? 0,
          approvalStatus: approvalStatus,
          isActive: isActive,
          rating: double.tryParse(m['avg_rating']?.toString() ?? '0') ?? 0,
          sku: m['sku']?.toString() ?? '',
        );
      }).toList();

      final names = products.map((p) => p.supplier).where((s) => s.isNotEmpty).toSet().toList()..sort();

      setState(() {
        _products = products;
        _supplierNames = ['all', ...names];
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load products. Pull down to retry.'; _loading = false; });
    }
  }

  Future<void> _approveProduct(_SupplierProduct product) async {
    try {
      await AdminService.updateProductStatus(product.id, isActive: true);
      if (!mounted) return;
      setState(() {
        product.approvalStatus = 'approved';
        product.isActive = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve product')));
    }
  }

  Future<void> _rejectProduct(_SupplierProduct product) async {
    try {
      await AdminService.updateProductStatus(product.id, isActive: false);
      if (!mounted) return;
      setState(() {
        product.approvalStatus = 'rejected';
        product.isActive = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reject product')));
    }
  }

  Future<void> _toggleActive(_SupplierProduct product) async {
    final next = !product.isActive;
    try {
      await AdminService.updateProductStatus(product.id, isActive: next);
      if (!mounted) return;
      setState(() => product.isActive = next);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update product status')));
    }
  }

  List<_SupplierProduct> _filtered(String status) {
    final base = _products ?? [];
    var list = base.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.supplier.toLowerCase().contains(q);
      final matchSupplier =
          _supplierFilter == 'all' || p.supplier == _supplierFilter;
      return matchSearch && matchSupplier;
    }).toList();
    if (status != 'all') {
      list = list.where((p) => p.approvalStatus == status).toList();
    }
    return list;
  }

  int get _pendingCount =>
      (_products ?? []).where((p) => p.approvalStatus == 'pending').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Supplier Products',
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
                        color: Colors.orange,
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
            const Tab(text: 'Active'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _fetchData, child: const Text('Retry')),
                    ]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: Column(
                    children: [
                      _buildFilters(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _buildList('all'),
                            _buildList('pending'),
                            _buildList('approved'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              setState(() => _searchQuery = v);
              _fetchData();
            },
            decoration: InputDecoration(
              hintText: 'Search by name, SKU, or supplier…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                        _fetchData();
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
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _supplierNames.map((s) {
                final selected = _supplierFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s == 'all' ? 'All Suppliers' : s,
                        style: TextStyle(
                            color: selected
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 12)),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _supplierFilter = s),
                    selectedColor: AppColors.secondary.withOpacity(0.15),
                    checkmarkColor: AppColors.secondary,
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                        color: selected
                            ? AppColors.secondary.withOpacity(0.4)
                            : AppColors.divider),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(String status) {
    final list = _filtered(status);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('No products found',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: list.length,
      itemBuilder: (_, i) => _ProductAdminCard(
        product: list[i],
        onApprove: list[i].approvalStatus == 'pending'
            ? () => _approveProduct(list[i])
            : null,
        onReject: list[i].approvalStatus == 'pending'
            ? () => _showRejectProductDialog(list[i])
            : null,
        onToggleActive: () => _toggleActive(list[i]),
        onView: () => _showProductSheet(list[i]),
      ),
    );
  }

  void _showRejectProductDialog(_SupplierProduct product) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Product',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting: "${product.name}"',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Reason (sent to supplier)…',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectProduct(product);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProductSheet(_SupplierProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(product.name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ),
                  _ApprovalBadge(product.approvalStatus),
                ],
              ),
              const SizedBox(height: 4),
              Text('${product.supplier} · ${product.category}',
                  style:
                      const TextStyle(color: AppColors.textSecondary)),
              const Divider(height: 24),
              _DetailRow(Icons.sell_outlined, 'Price',
                  'QAR ${product.price.toStringAsFixed(2)}'),
              _DetailRow(Icons.inventory_outlined, 'Stock',
                  '${product.stock} units'),
              _DetailRow(Icons.tag_outlined, 'SKU', product.sku),
              if (product.rating > 0)
                _DetailRow(Icons.star_outlined, 'Rating',
                    '${product.rating.toStringAsFixed(1)} ★'),
              const Divider(height: 24),
              StatefulBuilder(
                builder: (ctx, setLocal) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active on Store',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    Switch(
                      value: product.isActive,
                      onChanged: (v) async {
                        await _toggleActive(product);
                        setLocal(() {});
                        if (mounted) Navigator.pop(context);
                      },
                      activeColor: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductAdminCard extends StatelessWidget {
  final _SupplierProduct product;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback onToggleActive;
  final VoidCallback onView;

  const _ProductAdminCard({
    required this.product,
    this.onApprove,
    this.onReject,
    required this.onToggleActive,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: product.approvalStatus == 'pending'
              ? Colors.orange.withOpacity(0.4)
              : AppColors.divider,
          width: product.approvalStatus == 'pending' ? 1.5 : 1,
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
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                            '${product.supplier} · ${product.sku}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  _ApprovalBadge(product.approvalStatus),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('QAR ${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 12),
                  Icon(Icons.inventory_outlined,
                      size: 13,
                      color: product.stock == 0
                          ? Colors.red
                          : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${product.stock} in stock',
                      style: TextStyle(
                          fontSize: 12,
                          color: product.stock == 0
                              ? Colors.red
                              : AppColors.textSecondary)),
                  if (product.rating > 0) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.star_rounded,
                        size: 13, color: Color(0xFFFFB300)),
                    const SizedBox(width: 2),
                    Text(product.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ],
                ],
              ),
              if (onApprove != null || onReject != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onReject != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Reject',
                              style: TextStyle(
                                  color: Colors.red, fontSize: 13)),
                        ),
                      ),
                    if (onReject != null && onApprove != null)
                      const SizedBox(width: 8),
                    if (onApprove != null)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: onApprove,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Approve & Publish',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ),
                      ),
                  ],
                ),
              ] else if (product.approvalStatus == 'approved') ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active on store',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    Switch(
                      value: product.isActive,
                      onChanged: (_) => onToggleActive(),
                      activeColor: AppColors.secondary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalBadge extends StatelessWidget {
  final String status;
  const _ApprovalBadge(this.status);

  Color get _color => switch (status) {
        'approved' => const Color(0xFF2E7D32),
        'pending' => Colors.orange,
        'rejected' => Colors.red,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _SupplierProduct {
  final String id, name, supplier, category, sku;
  final double price, rating;
  final int stock;
  String approvalStatus;
  bool isActive;

  _SupplierProduct({
    required this.id,
    required this.name,
    required this.supplier,
    required this.category,
    required this.price,
    required this.stock,
    required this.approvalStatus,
    required this.isActive,
    required this.rating,
    required this.sku,
  });
}
