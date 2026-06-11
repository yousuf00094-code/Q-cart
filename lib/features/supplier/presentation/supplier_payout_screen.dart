import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SupplierPayoutScreen extends StatefulWidget {
  const SupplierPayoutScreen({super.key});

  @override
  State<SupplierPayoutScreen> createState() => _SupplierPayoutScreenState();
}

class _SupplierPayoutScreenState extends State<SupplierPayoutScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final List<_PayoutRecord> _payouts = [
    _PayoutRecord('PAY-2301', 'QAR 8,450.00', 'completed',
        '1 Jun 2026', '28 May – 31 May', 'QIIB ••••4521'),
    _PayoutRecord('PAY-2245', 'QAR 11,230.50', 'completed',
        '1 May 2026', '28 Apr – 30 Apr', 'QIIB ••••4521'),
    _PayoutRecord('PAY-2198', 'QAR 7,890.00', 'completed',
        '1 Apr 2026', '29 Mar – 31 Mar', 'QIIB ••••4521'),
    _PayoutRecord('PAY-2301B', 'QAR 4,120.75', 'pending',
        'Est. 15 Jun 2026', '1 Jun – 14 Jun', 'QIIB ••••4521'),
  ];

  final List<_Transaction> _transactions = [
    _Transaction('ORD-4201', 'Order Sale', '+QAR 245.00', 'credit', '10 Jun'),
    _Transaction('ORD-4198', 'Order Sale', '+QAR 89.50', 'credit', '9 Jun'),
    _Transaction('COM-4201', 'Q Cart Commission', '-QAR 24.50', 'debit', '10 Jun'),
    _Transaction('ORD-4185', 'Order Sale', '+QAR 512.00', 'credit', '8 Jun'),
    _Transaction('COM-4198', 'Q Cart Commission', '-QAR 8.95', 'debit', '9 Jun'),
    _Transaction('REF-4130', 'Refund Issued', '-QAR 89.50', 'debit', '7 Jun'),
    _Transaction('ORD-4172', 'Order Sale', '+QAR 67.00', 'credit', '7 Jun'),
    _Transaction('COM-4185', 'Q Cart Commission', '-QAR 51.20', 'debit', '8 Jun'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
    return SingleChildScrollView(
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
    );
  }

  Widget _buildBalanceCard() {
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
          const Text('QAR 4,120.75',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _BalanceStat('Pending', 'QAR 1,240.00'),
              _BalanceStat('Processing', 'QAR 0.00'),
              _BalanceStat('Next Payout', '15 Jun'),
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
          const Text('This Period (Jun 1–14)',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15)),
          const SizedBox(height: 14),
          ...[
            ('Gross Sales', 'QAR 5,720.50', false),
            ('Q Cart Commission (10%)', '- QAR 572.05', false),
            ('VAT Collected (5%)', '- QAR 286.00', false),
            ('Refunds Issued', '- QAR 89.50', false),
            ('COD Collection Fee', '- QAR 20.00', false),
            ('Net Payout', 'QAR 4,752.95', true),
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
          _BankDetailRow(Icons.account_balance_outlined, 'Bank', 'QIIB – Qatar International Islamic Bank'),
          _BankDetailRow(Icons.credit_card_outlined, 'Account', '••••  ••••  ••••  4521'),
          _BankDetailRow(Icons.person_outline, 'Account Name', 'TechStore Qatar LLC'),
          _BankDetailRow(Icons.tag_outlined, 'IBAN', 'QA58 QIIB 0000 0000 1234 0000 4521'),
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payouts.length,
      itemBuilder: (_, i) => _PayoutCard(payout: _payouts[i]),
    );
  }

  Widget _buildTransactionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (_, i) => _TransactionRow(txn: _transactions[i]),
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
            const Text(
                'Available balance: QAR 4,120.75\nEarly payout fee: QAR 15 flat',
                style: TextStyle(color: AppColors.textSecondary)),
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

class _PayoutCard extends StatelessWidget {
  final _PayoutRecord payout;
  const _PayoutCard({required this.payout});

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
                Text(payout.period,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text('${payout.bank} · ${payout.date}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(payout.amount,
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

class _TransactionRow extends StatelessWidget {
  final _Transaction txn;
  const _TransactionRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.type == 'credit';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCredit
                  ? const Color(0xFF2E7D32).withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add_outlined : Icons.remove_outlined,
              color: isCredit ? const Color(0xFF2E7D32) : Colors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        fontSize: 13)),
                Text('${txn.reference} · ${txn.date}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            txn.amount,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isCredit
                    ? const Color(0xFF2E7D32)
                    : Colors.red),
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

class _PayoutRecord {
  final String id, amount, status, date, period, bank;
  const _PayoutRecord(
      this.id, this.amount, this.status, this.date, this.period, this.bank);
}

class _Transaction {
  final String reference, description, amount, type, date;
  const _Transaction(
      this.reference, this.description, this.amount, this.type, this.date);
}
