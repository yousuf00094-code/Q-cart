import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AdminSupplierApprovalScreen extends StatefulWidget {
  const AdminSupplierApprovalScreen({super.key});

  @override
  State<AdminSupplierApprovalScreen> createState() =>
      _AdminSupplierApprovalScreenState();
}

class _AdminSupplierApprovalScreenState
    extends State<AdminSupplierApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<_SupplierApplication> _applications = [
    _SupplierApplication(
      'TechVision Qatar',
      'Mohammed Al-Rashid',
      'tech@techvisionqa.com',
      '+974 5512 3456',
      'Electronics',
      'pending',
      '8 Jun 2026',
      '45678901',
      false,
    ),
    _SupplierApplication(
      'Doha Fashion House',
      'Aisha Al-Mansoori',
      'info@dohafashion.qa',
      '+974 5578 9012',
      'Clothing & Apparel',
      'pending',
      '7 Jun 2026',
      '78901234',
      true,
    ),
    _SupplierApplication(
      'Qatar Home Essentials',
      'Khalid Al-Dosari',
      'sales@qhe.qa',
      '+974 5534 5678',
      'Home & Garden',
      'pending',
      '6 Jun 2026',
      '12345678',
      false,
    ),
    _SupplierApplication(
      'AlFahad Electronics',
      'Fahad Al-Qahtani',
      'fahad@alfahadelec.com',
      '+974 5556 7890',
      'Electronics',
      'approved',
      '5 Jun 2026',
      '34567890',
      true,
    ),
    _SupplierApplication(
      'Gulf Sports Co.',
      'Omar Al-Thani',
      'info@gulfsports.qa',
      '+974 5523 4567',
      'Sports & Outdoors',
      'rejected',
      '4 Jun 2026',
      '90123456',
      false,
    ),
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

  List<_SupplierApplication> _filtered(String status) {
    var list = _applications.where((a) {
      final q = _searchQuery.toLowerCase();
      return a.companyName.toLowerCase().contains(q) ||
          a.contactName.toLowerCase().contains(q) ||
          a.email.toLowerCase().contains(q);
    }).toList();
    if (status != 'all') {
      list = list.where((a) => a.status == status).toList();
    }
    return list;
  }

  int get _pendingCount =>
      _applications.where((a) => a.status == 'pending').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Supplier Approval',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          tabs: [
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
            const Tab(text: 'Approved'),
            const Tab(text: 'Rejected'),
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
                _buildList('pending'),
                _buildList('approved'),
                _buildList('rejected'),
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
          hintText: 'Search company name or email…',
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

  Widget _buildList(String status) {
    final list = _filtered(status);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory_outlined,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              status == 'pending'
                  ? 'No pending applications'
                  : 'No applications found',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: list.length,
      itemBuilder: (_, i) => _ApplicationCard(
        application: list[i],
        onApprove: list[i].status == 'pending'
            ? () => _handleDecision(list[i], 'approved')
            : null,
        onReject: list[i].status == 'pending'
            ? () => _showRejectDialog(list[i])
            : null,
        onView: () => _showDetailSheet(list[i]),
      ),
    );
  }

  void _handleDecision(_SupplierApplication app, String decision) {
    setState(() => app.status = decision);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${app.companyName} has been ${decision == 'approved' ? 'approved' : 'rejected'}'),
        backgroundColor:
            decision == 'approved' ? const Color(0xFF2E7D32) : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRejectDialog(_SupplierApplication app) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Application',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject ${app.companyName}?',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Reason for rejection (sent to applicant)…',
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
              _handleDecision(app, 'rejected');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(_SupplierApplication app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(app.companyName[0],
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.companyName,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        Text(app.category,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  _StatusBadge(app.status),
                ],
              ),
              const Divider(height: 28),
              const Text('Contact Information',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _DetailRow(Icons.person_outline, 'Contact', app.contactName),
              _DetailRow(Icons.email_outlined, 'Email', app.email),
              _DetailRow(Icons.phone_outlined, 'Phone', app.phone),
              _DetailRow(Icons.badge_outlined, 'CR Number', app.crNumber),
              _DetailRow(Icons.event_outlined, 'Applied', app.appliedDate),
              const Divider(height: 24),
              const Text('Verification',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _VerificationRow('Commercial Registration', app.hasDocuments),
              _VerificationRow('Tax Registration', app.hasDocuments),
              _VerificationRow('Bank Details', true),
              if (app.status == 'pending') ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showRejectDialog(app);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reject',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleDecision(app, 'approved');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Approve Supplier',
                            style: TextStyle(color: Colors.white)),
                      ),
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

class _ApplicationCard extends StatelessWidget {
  final _SupplierApplication application;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback onView;

  const _ApplicationCard({
    required this.application,
    this.onApprove,
    this.onReject,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(application.companyName[0],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                              fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(application.companyName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text(
                            '${application.contactName} · ${application.category}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  _StatusBadge(application.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(application.appliedDate,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  Icon(
                    application.hasDocuments
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    size: 13,
                    color: application.hasDocuments
                        ? const Color(0xFF2E7D32)
                        : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    application.hasDocuments
                        ? 'Documents verified'
                        : 'Docs pending',
                    style: TextStyle(
                        fontSize: 12,
                        color: application.hasDocuments
                            ? const Color(0xFF2E7D32)
                            : Colors.orange),
                  ),
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
                            side: const BorderSide(
                                color: Colors.red, width: 1),
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
                          child: const Text('Approve',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ),
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  Color get _color => switch (status) {
        'pending' => Colors.orange,
        'approved' => const Color(0xFF2E7D32),
        'rejected' => Colors.red,
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _color)),
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
            width: 80,
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

class _VerificationRow extends StatelessWidget {
  final String label;
  final bool verified;
  const _VerificationRow(this.label, this.verified);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            verified
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            size: 18,
            color: verified ? const Color(0xFF2E7D32) : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary)),
          const Spacer(),
          Text(verified ? 'Verified' : 'Pending',
              style: TextStyle(
                  fontSize: 12,
                  color: verified
                      ? const Color(0xFF2E7D32)
                      : Colors.orange,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SupplierApplication {
  final String companyName, contactName, email, phone, category;
  String status;
  final String appliedDate, crNumber;
  final bool hasDocuments;

  _SupplierApplication(
    this.companyName,
    this.contactName,
    this.email,
    this.phone,
    this.category,
    this.status,
    this.appliedDate,
    this.crNumber,
    this.hasDocuments,
  );
}
