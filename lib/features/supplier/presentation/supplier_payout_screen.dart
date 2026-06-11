import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supplier_service.dart';
import '../../../core/services/api_client.dart';

class SupplierPayoutScreen extends StatefulWidget {
  const SupplierPayoutScreen({super.key});

  @override
  State<SupplierPayoutScreen> createState() => _SupplierPayoutScreenState();
}

class _SupplierPayoutScreenState extends State<SupplierPayoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  List<_PayoutRecord>? _payouts;
  bool _loading = true;
  String? _error;
  String _filterStatus = 'all';

  // Per-payout items cache: payout id → list of items
  final Map<String, List<_PayoutItem>> _payoutItems = {};
  final Set<String> _loadingItems = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _fetchPayouts();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPayouts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await SupplierService.getPayouts(
        page: 1,
        status: _filterStatus == 'all' ? null : _filterStatus,
      );
      if (!mounted) return;
      final data = raw['data'] as List<dynamic>? ?? [];
      setState(() {
        _payouts = data.map((e) => _PayoutRecord.fromJson(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load. Pull down to retry.';
        _loading = false;
      });
    }
  }

  Future<void> _fetchPayoutItems(String payoutId) async {
    if (_payoutItems.containsKey(payoutId) || _loadingItems.contains(payoutId)) return;
    setState(() => _loadingItems.add(payoutId));
    try {
      final raw = await SupplierService.getPayout(payoutId);
      if (!mounted) return;
      final items = (raw['items'] as List<dynamic>? ?? [])
          .map((e) => _PayoutItem.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _payoutItems[payoutId] = items;
        _loadingItems.remove(payoutId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingItems.remove(payoutId));
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso) ?? DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatPeriod(String start, String end) {
    final s = DateTime.tryParse(start) ?? DateTime.now();
    final e = DateTime.tryParse(end) ?? DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${s.day} ${months[s.month - 1]} – ${e.day} ${months[e.month - 1]}';
  }

  double get _totalPaid {
    if (_payouts == null) return 0;
    return _payouts!
        .where((p) => p.status == 'paid' || p.status == 'completed')
        .fold(0.0, (sum, p) => sum + p.netAmount);
  }

  double get _totalPending {
    if (_payouts == null) return 0;
    return _payouts!
        .where((p) => p.status == 'pending')
        .fold(0.0, (sum, p) => sum + p.netAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Payouts',
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
            tooltip: 'Export Statement',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Payouts'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildOverviewTab(),
          _buildPayoutsTab(),
          _buildTransactionsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchPayouts, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchPayouts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 16),
            _buildPayoutBreakdown(),
            const SizedBox(height: 16),
            _buildBankDetails(),
            const SizedBox(height: 16),
            _buildPayoutScheduleCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final pending = _totalPending;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Balance',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text('QAR ${pending.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _BalanceStat('Pending', 'QAR ${pending.toStringAsFixed(2)}'),
              _BalanceStat('Processing', 'QAR 0.00'),
              _BalanceStat('Next Payout', '15th'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showWithdrawSheet(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Request Early Payout',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutBreakdown() {
    final paid = _totalPaid;
    final pending = _totalPending;
    final total = paid + pending;
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
          const Text('Payout Summary',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15)),
          const SizedBox(height: 14),
          ...[
            ('Total Payouts', 'QAR ${total.toStringAsFixed(2)}', false),
            ('Paid Out', 'QAR ${paid.toStringAsFixed(2)}', false),
            ('Pending', 'QAR ${pending.toStringAsFixed(2)}', false),
            ('Net Balance', 'QAR ${pending.toStringAsFixed(2)}', true),
          ].map((row) => Column(
                children: [
                  if (row.$3) const Divider(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(row.$1,
                            style: TextStyle(
                                fontSize: row.$3 ? 14 : 13,
                                fontWeight: row.$3
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: row.$3
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary)),
                        Text(row.$2,
                            style: TextStyle(
                                fontSize: row.$3 ? 14 : 13,
                                fontWeight: row.$3
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: row.$3
                                    ? const Color(0xFF2E7D32)
                                    : AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildBankDetails() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bank Account',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 15)),
              TextButton(
                onPressed: () => _showUpdateBankSheet(),
                child: const Text('Update',
                    style: TextStyle(color: AppColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _BankDetailRow(Icons.account_balance_outlined, 'Bank', 'On File'),
          const _BankDetailRow(Icons.credit_card_outlined, 'Account', 'On File'),
          const _BankDetailRow(Icons.person_outline, 'Account Name', 'On File'),
          const _BankDetailRow(Icons.tag_outlined, 'IBAN', 'On File'),
        ],
      ),
    );
  }

  Widget _buildPayoutScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_outlined, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text('Payout Schedule',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Payouts are processed twice monthly on the 1st and 15th of each month. Funds typically arrive within 1–2 business days.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 8),
          const Text('Minimum payout threshold: QAR 100',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPayoutsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchPayouts, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final payouts = _payouts ?? [];
    return Column(
      children: [
        _buildStatusFilter(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchPayouts,
            child: payouts.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text('No payouts found',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: payouts.length,
                    itemBuilder: (_, i) => _PayoutCard(
                      payout: payouts[i],
                      formatDate: _formatDate,
                      formatPeriod: _formatPeriod,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    final filters = [
      ('all', 'All'),
      ('pending', 'Pending'),
      ('paid', 'Paid'),
    ];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: filters.map((f) {
          final selected = _filterStatus == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.$2,
                  style: TextStyle(
                      color: selected ? AppColors.secondary : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13)),
              selected: selected,
              onSelected: (_) {
                setState(() => _filterStatus = f.$1);
                _fetchPayouts();
              },
              selectedColor: AppColors.secondary.withOpacity(0.15),
              checkmarkColor: AppColors.secondary,
              backgroundColor: AppColors.background,
              side: BorderSide(
                  color: selected
                      ? AppColors.secondary.withOpacity(0.4)
                      : AppColors.divider),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchPayouts, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final payouts = _payouts ?? [];
    return RefreshIndicator(
      onRefresh: _fetchPayouts,
      child: payouts.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text('No transactions found',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payouts.length,
              itemBuilder: (_, i) {
                final payout = payouts[i];
                final items = _payoutItems[payout.id];
                final isLoadingItems = _loadingItems.contains(payout.id);
                return _PayoutTransactionTile(
                  payout: payout,
                  items: items,
                  isLoadingItems: isLoadingItems,
                  formatDate: _formatDate,
                  formatPeriod: _formatPeriod,
                  onExpand: () => _fetchPayoutItems(payout.id),
                );
              },
            ),
    );
  }

  void _showWithdrawSheet() {
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
            const Text('Request Early Payout',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
                'Available balance: QAR ${_totalPending.toStringAsFixed(2)}\nEarly payout fee: QAR 15 flat',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (QAR)',
                prefixIcon: Icon(Icons.payments_outlined),
                prefixText: 'QAR ',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Request Payout',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateBankSheet() {
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
            const Text('Update Bank Account',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ...['Bank Name', 'Account Number', 'Account Holder Name', 'IBAN']
                .map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                          decoration: InputDecoration(labelText: f)),
                    )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Bank Details',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction tile with expand-to-load items ──────────────────────────────

class _PayoutTransactionTile extends StatefulWidget {
  final _PayoutRecord payout;
  final List<_PayoutItem>? items;
  final bool isLoadingItems;
  final String Function(String) formatDate;
  final String Function(String, String) formatPeriod;
  final VoidCallback onExpand;

  const _PayoutTransactionTile({
    required this.payout,
    required this.items,
    required this.isLoadingItems,
    required this.formatDate,
    required this.formatPeriod,
    required this.onExpand,
  });

  @override
  State<_PayoutTransactionTile> createState() => _PayoutTransactionTileState();
}

class _PayoutTransactionTileState extends State<_PayoutTransactionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final payout = widget.payout;
    final isPending = payout.status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (!_expanded) widget.onExpand();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isPending
                          ? const Color(0xFFF57F17).withOpacity(0.1)
                          : const Color(0xFF2E7D32).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPending ? Icons.hourglass_empty_outlined : Icons.receipt_long_outlined,
                      color: isPending ? const Color(0xFFF57F17) : const Color(0xFF2E7D32),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payout.id,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                                fontSize: 13)),
                        Text(
                          '${widget.formatPeriod(payout.periodStart, payout.periodEnd)} · ${widget.formatDate(payout.periodStart)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'QAR ${payout.netAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isPending ? const Color(0xFFF57F17) : const Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            if (widget.isLoadingItems)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (widget.items == null)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Could not load items.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              )
            else if (widget.items!.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No line items.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Column(
                  children: widget.items!.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.orderNumber,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary)),
                              Text('Commission: QAR ${item.commission.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('QAR ${item.net.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E7D32))),
                            Text('Gross: QAR ${item.gross.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Stateless widget classes ─────────────────────────────────────────────────

class _PayoutCard extends StatelessWidget {
  final _PayoutRecord payout;
  final String Function(String) formatDate;
  final String Function(String, String) formatPeriod;
  const _PayoutCard({
    required this.payout,
    required this.formatDate,
    required this.formatPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = payout.status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? const Color(0xFFF57F17).withOpacity(0.4)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPending
                  ? const Color(0xFFF57F17).withOpacity(0.1)
                  : const Color(0xFF2E7D32).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPending
                  ? Icons.hourglass_empty_outlined
                  : Icons.check_circle_outline,
              color: isPending
                  ? const Color(0xFFF57F17)
                  : const Color(0xFF2E7D32),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payout.id,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(formatPeriod(payout.periodStart, payout.periodEnd),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text('On File · ${formatDate(payout.periodStart)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('QAR ${payout.netAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isPending
                          ? const Color(0xFFF57F17)
                          : const Color(0xFF2E7D32))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFF57F17).withOpacity(0.1)
                      : const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPending ? 'Pending' : 'Completed',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPending
                          ? const Color(0xFFF57F17)
                          : const Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label, value;
  const _BalanceStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 13)),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _BankDetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
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

// ── Data models ───────────────────────────────────────────────────────────────

class _PayoutRecord {
  final String id;
  final double netAmount;
  final double grossAmount;
  final double commissionAmount;
  final String status;
  final String periodStart;
  final String periodEnd;

  const _PayoutRecord({
    required this.id,
    required this.netAmount,
    required this.grossAmount,
    required this.commissionAmount,
    required this.status,
    required this.periodStart,
    required this.periodEnd,
  });

  factory _PayoutRecord.fromJson(Map<String, dynamic> j) {
    return _PayoutRecord(
      id: j['id']?.toString() ?? '',
      netAmount: (j['net_amount'] as num?)?.toDouble() ?? 0.0,
      grossAmount: (j['gross_amount'] as num?)?.toDouble() ?? 0.0,
      commissionAmount: (j['commission_amount'] as num?)?.toDouble() ?? 0.0,
      status: j['status']?.toString() ?? 'pending',
      periodStart: j['period_start']?.toString() ?? '',
      periodEnd: j['period_end']?.toString() ?? '',
    );
  }
}

class _PayoutItem {
  final String id;
  final String orderNumber;
  final double net;
  final double gross;
  final double commission;

  const _PayoutItem({
    required this.id,
    required this.orderNumber,
    required this.net,
    required this.gross,
    required this.commission,
  });

  factory _PayoutItem.fromJson(Map<String, dynamic> j) {
    return _PayoutItem(
      id: j['id']?.toString() ?? '',
      orderNumber: j['order_number']?.toString() ?? '',
      net: (j['net'] as num?)?.toDouble() ?? 0.0,
      gross: (j['gross'] as num?)?.toDouble() ?? 0.0,
      commission: (j['commission'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
