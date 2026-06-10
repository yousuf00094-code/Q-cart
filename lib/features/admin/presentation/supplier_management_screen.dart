import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() => _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  String _query = '';

  static final List<_Supplier> _all = [
    _Supplier(id: 'S001', name: 'Al Meera Consumer Goods', email: 'partner@almeera.com.qa',
        contact: 'Hassan Al-Kuwari', phone: '+974 4412 3456', products: 84,
        status: _SupplierStatus.active, rating: 4.7),
    _Supplier(id: 'S002', name: 'Qatar Spices Co.', email: 'info@qatarspices.qa',
        contact: 'Noor Al-Rashid', phone: '+974 5512 9900', products: 32,
        status: _SupplierStatus.active, rating: 4.2),
    _Supplier(id: 'S003', name: 'Gulf Fresh Dairy', email: 'supply@gulffresh.qa',
        contact: 'Khalid Al-Thani', phone: '+974 4498 0011', products: 18,
        status: _SupplierStatus.active, rating: 3.9),
    _Supplier(id: 'S004', name: 'Organic Valley QA', email: 'hello@orgvalley.qa',
        contact: 'Maryam Al-Nasr', phone: '+974 5533 7721', products: 0,
        status: _SupplierStatus.pending, rating: 0),
    _Supplier(id: 'S005', name: 'TechSupply Middle East', email: 'b2b@techsupply.qa',
        contact: 'Rashed Al-Dosari', phone: '+974 4401 5566', products: 55,
        status: _SupplierStatus.active, rating: 4.5),
    _Supplier(id: 'S006', name: 'Desert Farms LLC', email: 'ops@desertfarms.qa',
        contact: 'Sara Al-Emadi', phone: '+974 5520 4433', products: 12,
        status: _SupplierStatus.inactive, rating: 3.1),
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

  List<_Supplier> _filtered(_SupplierStatus? status) {
    return _all.where((s) {
      final matchStatus = status == null || s.status == status;
      final matchQuery = _query.isEmpty ||
          s.name.toLowerCase().contains(_query.toLowerCase()) ||
          s.email.toLowerCase().contains(_query.toLowerCase());
      return matchStatus && matchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Supplier Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
            onPressed: () => _showSupplierSheet(context, null),
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
              tabs: const [Tab(text: 'All'), Tab(text: 'Active'), Tab(text: 'Pending')],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearch(),
          _buildSummaryRow(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _SupplierList(suppliers: _filtered(null), onTap: (s) => _showDetail(context, s), onEdit: (s) => _showSupplierSheet(context, s)),
                _SupplierList(suppliers: _filtered(_SupplierStatus.active), onTap: (s) => _showDetail(context, s), onEdit: (s) => _showSupplierSheet(context, s)),
                _SupplierList(suppliers: _filtered(_SupplierStatus.pending), onTap: (s) => _showDetail(context, s), onEdit: (s) => _showSupplierSheet(context, s)),
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
          hintText: 'Search suppliers…',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                  onPressed: () => setState(() { _searchCtrl.clear(); _query = ''; }),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final active = _all.where((s) => s.status == _SupplierStatus.active).length;
    final pending = _all.where((s) => s.status == _SupplierStatus.pending).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _StatPill('${_all.length} Total', AppColors.surface, AppColors.textPrimary),
          const SizedBox(width: 8),
          _StatPill('$active Active', const Color(0xFFE8F5E9), const Color(0xFF388E3C)),
          const SizedBox(width: 8),
          if (pending > 0)
            _StatPill('$pending Pending', const Color(0xFFFFF3E0), const Color(0xFFF57C00)),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, _Supplier s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupplierDetailSheet(supplier: s),
    );
  }

  void _showSupplierSheet(BuildContext context, _Supplier? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupplierFormSheet(existing: existing),
    );
  }
}

class _SupplierList extends StatelessWidget {
  const _SupplierList({required this.suppliers, required this.onTap, required this.onEdit});
  final List<_Supplier> suppliers;
  final void Function(_Supplier) onTap;
  final void Function(_Supplier) onEdit;

  @override
  Widget build(BuildContext context) {
    if (suppliers.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.business_outlined, size: 48, color: AppColors.textSecondary),
          SizedBox(height: 10),
          Text('No suppliers found', style: TextStyle(color: AppColors.textSecondary)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: suppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _SupplierCard(supplier: suppliers[i], onTap: onTap, onEdit: onEdit),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({required this.supplier, required this.onTap, required this.onEdit});
  final _Supplier supplier;
  final void Function(_Supplier) onTap;
  final void Function(_Supplier) onEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(supplier),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  supplier.name[0],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.secondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(supplier.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(supplier.email,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            _StatusBadge(status: supplier.status),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Row(children: [
            _InfoChip(Icons.person_outline, supplier.contact),
            const SizedBox(width: 12),
            _InfoChip(Icons.inventory_2_outlined, '${supplier.products} products'),
            const Spacer(),
            if (supplier.rating > 0) ...[
              const Icon(Icons.star, size: 13, color: Color(0xFFFFC107)),
              const SizedBox(width: 2),
              Text(supplier.rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onEdit(supplier),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _SupplierDetailSheet extends StatelessWidget {
  const _SupplierDetailSheet({required this.supplier});
  final _Supplier supplier;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(controller: ctrl, children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(supplier.name[0],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.secondary))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(supplier.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              _StatusBadge(status: supplier.status),
            ])),
          ]),
          const SizedBox(height: 20),
          _DetailRow(Icons.email_outlined, 'Email', supplier.email),
          _DetailRow(Icons.phone_outlined, 'Phone', supplier.phone),
          _DetailRow(Icons.person_outline, 'Contact', supplier.contact),
          _DetailRow(Icons.inventory_2_outlined, 'Products', '${supplier.products} active listings'),
          if (supplier.rating > 0)
            _DetailRow(Icons.star_outline, 'Rating', '${supplier.rating.toStringAsFixed(1)} / 5.0'),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.block, size: 16),
                label: const Text('Suspend'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                  side: const BorderSide(color: Color(0xFFE53935)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.email_outlined, size: 16),
                label: const Text('Contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _SupplierFormSheet extends StatelessWidget {
  const _SupplierFormSheet({this.existing});
  final _Supplier? existing;

  @override
  Widget build(BuildContext context) {
    final isEdit = existing != null;
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
          Text(isEdit ? 'Edit Supplier' : 'Add Supplier',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          _FormField(label: 'Company Name', initial: existing?.name),
          const SizedBox(height: 12),
          _FormField(label: 'Email Address', initial: existing?.email),
          const SizedBox(height: 12),
          _FormField(label: 'Phone Number', initial: existing?.phone),
          const SizedBox(height: 12),
          _FormField(label: 'Contact Person', initial: existing?.contact),
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
              child: Text(isEdit ? 'Save Changes' : 'Add Supplier',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Shared small widgets ──────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final _SupplierStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      _SupplierStatus.active  => ('Active',  const Color(0xFFE8F5E9), const Color(0xFF388E3C)),
      _SupplierStatus.pending => ('Pending', const Color(0xFFFFF3E0), const Color(0xFFF57C00)),
      _SupplierStatus.inactive=> ('Inactive',const Color(0xFFFFE8E8), const Color(0xFFE53935)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: AppColors.textSecondary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text('$label:', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(child: Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            textAlign: TextAlign.end)),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill(this.label, this.bg, this.fg);
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.label, this.initial});
  final String label;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initial,
      decoration: InputDecoration(labelText: label),
    );
  }
}

enum _SupplierStatus { active, pending, inactive }

class _Supplier {
  final String id, name, email, contact, phone;
  final int products;
  final _SupplierStatus status;
  final double rating;

  const _Supplier({
    required this.id, required this.name, required this.email,
    required this.contact, required this.phone, required this.products,
    required this.status, required this.rating,
  });
}
