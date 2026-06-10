import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  String _query = '';
  _SortOption _sort = _SortOption.newest;

  static final List<_Customer> _customers = [
    _Customer(id: 'C001', name: 'Fatima Al-Dosari', email: 'fatima@example.com',
        phone: '+974 5512 0001', orders: 14, totalSpent: 2840.0,
        loyaltyPoints: 520, status: _CustomerStatus.active, joinedDate: 'Jan 2024'),
    _Customer(id: 'C002', name: 'Mohammed Al-Thani', email: 'mohammed@example.com',
        phone: '+974 5522 0002', orders: 7, totalSpent: 1120.50,
        loyaltyPoints: 210, status: _CustomerStatus.active, joinedDate: 'Feb 2024'),
    _Customer(id: 'C003', name: 'Aisha Al-Kuwari', email: 'aisha@example.com',
        phone: '+974 5533 0003', orders: 31, totalSpent: 8450.0,
        loyaltyPoints: 1680, status: _CustomerStatus.vip, joinedDate: 'Nov 2023'),
    _Customer(id: 'C004', name: 'Omar Al-Nasr', email: 'omar@example.com',
        phone: '+974 5544 0004', orders: 2, totalSpent: 340.0,
        loyaltyPoints: 68, status: _CustomerStatus.active, joinedDate: 'May 2024'),
    _Customer(id: 'C005', name: 'Sara Al-Emadi', email: 'sara@example.com',
        phone: '+974 5555 0005', orders: 0, totalSpent: 0.0,
        loyaltyPoints: 0, status: _CustomerStatus.inactive, joinedDate: 'Jun 2024'),
    _Customer(id: 'C006', name: 'Khalid Al-Rashid', email: 'khalid@example.com',
        phone: '+974 5566 0006', orders: 22, totalSpent: 5900.0,
        loyaltyPoints: 1180, status: _CustomerStatus.vip, joinedDate: 'Sep 2023'),
    _Customer(id: 'C007', name: 'Noor Al-Qassim', email: 'noor@example.com',
        phone: '+974 5577 0007', orders: 5, totalSpent: 780.0,
        loyaltyPoints: 156, status: _CustomerStatus.active, joinedDate: 'Mar 2024'),
    _Customer(id: 'C008', name: 'Rashed Al-Mannai', email: 'rashed@example.com',
        phone: '+974 5588 0008', orders: 1, totalSpent: 55.0,
        loyaltyPoints: 11, status: _CustomerStatus.suspended, joinedDate: 'Apr 2024'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Customer> _filtered(_CustomerStatus? status) {
    var list = _customers.where((c) {
      final matchQuery = _query.isEmpty ||
          c.name.toLowerCase().contains(_query.toLowerCase()) ||
          c.email.toLowerCase().contains(_query.toLowerCase()) ||
          c.phone.contains(_query);
      final matchStatus = status == null || c.status == status;
      return matchQuery && matchStatus;
    }).toList();

    list.sort((a, b) => switch (_sort) {
          _SortOption.newest  => b.id.compareTo(a.id),
          _SortOption.topSpend => b.totalSpent.compareTo(a.totalSpent),
          _SortOption.mostOrders => b.orders.compareTo(a.orders),
        });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final vip        = _customers.where((c) => c.status == _CustomerStatus.vip).length;
    final active     = _customers.where((c) => c.status == _CustomerStatus.active).length;
    final suspended  = _customers.where((c) => c.status == _CustomerStatus.suspended).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Customers',
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
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(3),
              tabs: [
                const Tab(text: 'All'),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('VIP'),
                  if (vip > 0) ...[const SizedBox(width: 4), _Badge('$vip', const Color(0xFFFFC107))],
                ])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Active'),
                  if (active > 0) ...[const SizedBox(width: 4), _Badge('$active', const Color(0xFF388E3C))],
                ])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Suspended'),
                  if (suspended > 0) ...[const SizedBox(width: 4), _Badge('$suspended', const Color(0xFFE53935))],
                ])),
              ],
            ),
          ),
        ),
      ),
      body: Column(children: [
        _buildSearchAndSort(),
        _buildStatsRow(),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _CustomerList(customers: _filtered(null), onTap: (c) => _showDetail(context, c)),
              _CustomerList(customers: _filtered(_CustomerStatus.vip), onTap: (c) => _showDetail(context, c)),
              _CustomerList(customers: _filtered(_CustomerStatus.active), onTap: (c) => _showDetail(context, c)),
              _CustomerList(customers: _filtered(_CustomerStatus.suspended), onTap: (c) => _showDetail(context, c)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildSearchAndSort() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search by name, email, phone…',
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
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _showSortSheet(context),
          child: Container(
            width: 44, height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.sort, color: AppColors.secondary),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatsRow() {
    final totalRevenue = _customers.fold(0.0, (s, c) => s + c.totalSpent);
    final avgSpend = _customers.isNotEmpty ? totalRevenue / _customers.length : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        Expanded(child: _StatBox('${_customers.length}', 'Total', const Color(0xFFD4F5E9), const Color(0xFF388E3C))),
        const SizedBox(width: 8),
        Expanded(child: _StatBox('QAR ${(totalRevenue / 1000).toStringAsFixed(1)}k', 'Revenue', const Color(0xFFDDD9F5), const Color(0xFF7B1FA2))),
        const SizedBox(width: 8),
        Expanded(child: _StatBox('QAR ${avgSpend.toStringAsFixed(0)}', 'Avg. Spend', const Color(0xFFFFE8D6), const Color(0xFFF57C00))),
      ]),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Sort by', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ..._SortOption.values.map((opt) => ListTile(
            onTap: () { setState(() => _sort = opt); Navigator.pop(context); },
            title: Text(opt.label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            trailing: _sort == opt
                ? const Icon(Icons.check_circle, color: AppColors.secondary)
                : const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary),
            contentPadding: EdgeInsets.zero,
          )),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context, _Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerDetailSheet(customer: customer),
    );
  }
}

class _CustomerList extends StatelessWidget {
  const _CustomerList({required this.customers, required this.onTap});
  final List<_Customer> customers;
  final void Function(_Customer) onTap;

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.people_outline, size: 48, color: AppColors.textSecondary),
          SizedBox(height: 10),
          Text('No customers found', style: TextStyle(color: AppColors.textSecondary)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _CustomerCard(customer: customers[i], onTap: onTap),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onTap});
  final _Customer customer;
  final void Function(_Customer) onTap;

  String get _initials {
    final parts = customer.name.split(' ');
    return parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}' : customer.name[0];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(customer),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.secondary.withOpacity(0.12),
              child: Text(_initials, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.secondary)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(customer.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                _StatusBadge(status: customer.status),
              ]),
              const SizedBox(height: 2),
              Text(customer.email,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Row(children: [
            _MetricItem(Icons.shopping_bag_outlined, '${customer.orders}', 'orders'),
            const SizedBox(width: 16),
            _MetricItem(Icons.monetization_on_outlined, 'QAR ${customer.totalSpent.toStringAsFixed(0)}', 'spent'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.stars_rounded, size: 13, color: Color(0xFFFFC107)),
                const SizedBox(width: 4),
                Text('${customer.loyaltyPoints} pts',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF57C00))),
              ]),
            ),
            const SizedBox(width: 6),
            Text('Since ${customer.joinedDate}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ]),
      ),
    );
  }
}

class _CustomerDetailSheet extends StatelessWidget {
  const _CustomerDetailSheet({required this.customer});
  final _Customer customer;

  String get _initials {
    final parts = customer.name.split(' ');
    return parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}' : customer.name[0];
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(controller: ctrl, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.secondary.withOpacity(0.12),
              child: Text(_initials, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.secondary)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(customer.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              _StatusBadge(status: customer.status),
            ])),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Expanded(child: _DetailStat('${customer.orders}', 'Orders')),
              Container(width: 1, height: 32, color: Colors.white.withOpacity(0.2)),
              Expanded(child: _DetailStat('QAR ${customer.totalSpent.toStringAsFixed(0)}', 'Spent')),
              Container(width: 1, height: 32, color: Colors.white.withOpacity(0.2)),
              Expanded(child: _DetailStat('${customer.loyaltyPoints}', 'Points')),
            ]),
          ),
          const SizedBox(height: 16),
          _InfoRow(Icons.email_outlined, 'Email', customer.email),
          _InfoRow(Icons.phone_outlined, 'Phone', customer.phone),
          _InfoRow(Icons.calendar_today_outlined, 'Member Since', customer.joinedDate),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.email_outlined, size: 16),
                label: const Text('Send Email'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.block, size: 16),
                label: const Text('Suspend'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
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

// ─── Small widgets ─────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final _CustomerStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      _CustomerStatus.vip       => ('VIP',      const Color(0xFFFFF3E0), const Color(0xFFF57C00)),
      _CustomerStatus.active    => ('Active',   const Color(0xFFE8F5E9), const Color(0xFF388E3C)),
      _CustomerStatus.inactive  => ('Inactive', AppColors.surface,       AppColors.textSecondary),
      _CustomerStatus.suspended => ('Suspended',const Color(0xFFFFE8E8), const Color(0xFFE53935)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem(this.icon, this.value, this.label);
  final IconData icon;
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: AppColors.textSecondary),
      const SizedBox(width: 4),
      Text('$value $label', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat(this.value, this.label);
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7))),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
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

class _StatBox extends StatelessWidget {
  const _StatBox(this.value, this.label, this.bg, this.fg);
  final String value, label;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
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

// ─── Data ──────────────────────────────────────────────────────────────────

enum _CustomerStatus { vip, active, inactive, suspended }
enum _SortOption {
  newest('Newest First'),
  topSpend('Top Spenders'),
  mostOrders('Most Orders');

  final String label;
  const _SortOption(this.label);
}

class _Customer {
  final String id, name, email, phone, joinedDate;
  final int orders, loyaltyPoints;
  final double totalSpent;
  final _CustomerStatus status;

  const _Customer({
    required this.id, required this.name, required this.email,
    required this.phone, required this.orders, required this.totalSpent,
    required this.loyaltyPoints, required this.status, required this.joinedDate,
  });
}
