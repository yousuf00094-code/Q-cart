import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supplier_service.dart';
import '../../../core/services/api_client.dart';
import 'supplier_product_submission_screen.dart';

class SupplierProductApprovalScreen extends StatefulWidget {
  const SupplierProductApprovalScreen({super.key});

  @override
  State<SupplierProductApprovalScreen> createState() =>
      _SupplierProductApprovalScreenState();
}

class _SupplierProductApprovalScreenState
    extends State<SupplierProductApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _selectedFilter = 'All';

  static const _filters = ['All', 'Pending', 'Approved', 'Rejected', 'Draft'];

  List<_ProductSubmission>? _products;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _filters.length, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await SupplierService.getProducts(page: 1);
      if (!mounted) return;
      final data = res['data'] as List<dynamic>? ?? [];
      setState(() {
        _products = data.map((r) {
          final m = r as Map<String, dynamic>;
          final isActive = m['is_active'] == true;
          return _ProductSubmission(
            id: m['id']?.toString() ?? '',
            name: m['name']?.toString() ?? '',
            sku: m['sku']?.toString() ?? '',
            category: m['category_name']?.toString() ?? '',
            price: double.tryParse(m['price']?.toString() ?? '0') ?? 0,
            status: isActive ? _ApprovalStatus.active : _ApprovalStatus.pendingReview,
            submittedAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
            reviewedAt: null,
            reviewerNote: null,
            images: 0,
          );
        }).toList();
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

  List<_ProductSubmission> get _filtered {
    final all = _products ?? [];
    if (_selectedFilter == 'All') return all;
    return all.where((p) {
      switch (_selectedFilter) {
        case 'Pending':
          return p.status == _ApprovalStatus.pendingReview;
        case 'Approved':
          return p.status == _ApprovalStatus.approved || p.status == _ApprovalStatus.active;
        case 'Rejected':
          return p.status == _ApprovalStatus.rejected;
        case 'Draft':
          return p.status == _ApprovalStatus.draft;
        default:
          return true;
      }
    }).toList();
  }

  int _count(_ApprovalStatus s) =>
      (_products ?? []).where((p) => p.status == s).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Product Approvals',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SupplierProductSubmissionScreen())),
            icon: const Icon(Icons.add, size: 18, color: AppColors.secondary),
            label: const Text('Submit Product',
                style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: Column(
                    children: [
                      _buildSummaryBar(),
                      _buildFilterChips(),
                      const Divider(height: 1, color: AppColors.divider),
                      Expanded(
                        child: _filtered.isEmpty
                            ? _buildEmpty()
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, i) => _ProductCard(
                                  product: _filtered[i],
                                  onResubmit: _resubmit,
                                  onDelete: _delete,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _SummaryChip(
              label: 'Pending',
              count: _count(_ApprovalStatus.pendingReview),
              color: const Color(0xFFF57F17)),
          const SizedBox(width: 8),
          _SummaryChip(
              label: 'Approved',
              count: _count(_ApprovalStatus.approved) +
                  _count(_ApprovalStatus.active),
              color: const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          _SummaryChip(
              label: 'Rejected',
              count: _count(_ApprovalStatus.rejected),
              color: const Color(0xFFC62828)),
          const SizedBox(width: 8),
          _SummaryChip(
              label: 'Draft',
              count: _count(_ApprovalStatus.draft),
              color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: AppColors.background,
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final selected = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.secondary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(f,
                  style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No $_selectedFilter products',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  void _resubmit(_ProductSubmission p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SupplierProductSubmissionScreen()),
    );
  }

  void _delete(_ProductSubmission p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Draft'),
        content: Text('Delete "${p.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _products?.remove(p));
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final _ProductSubmission product;
  final void Function(_ProductSubmission) onResubmit;
  final void Function(_ProductSubmission) onDelete;

  const _ProductCard({
    required this.product,
    required this.onResubmit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('${product.sku} · ${product.category}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                _StatusBadge(status: product.status),
              ],
            ),
            const SizedBox(height: 12),
            _ApprovalTimeline(product: product),
            if (product.status == _ApprovalStatus.rejected &&
                product.reviewerNote != null) ...[
              const SizedBox(height: 12),
              _ReviewerNote(note: product.reviewerNote!),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text('QAR ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.secondary)),
                const SizedBox(width: 8),
                Text('${product.images} image${product.images != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                if (product.status == _ApprovalStatus.rejected)
                  TextButton(
                    onPressed: () => onResubmit(product),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        backgroundColor: AppColors.secondary.withOpacity(0.1)),
                    child: const Text('Edit & Resubmit',
                        style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                if (product.status == _ApprovalStatus.draft) ...[
                  IconButton(
                    onPressed: () => onDelete(product),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => onResubmit(product),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        backgroundColor: AppColors.primary.withOpacity(0.3)),
                    child: const Text('Continue Editing',
                        style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(product: product),
    );
  }
}

// ── Approval Timeline ─────────────────────────────────────────────────────────

class _ApprovalTimeline extends StatelessWidget {
  final _ProductSubmission product;
  const _ApprovalTimeline({required this.product});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep('Draft', _stepState(0)),
      _TimelineStep('Submitted', _stepState(1)),
      _TimelineStep('Under Review', _stepState(2)),
      _TimelineStep(
          product.status == _ApprovalStatus.rejected ? 'Rejected' : 'Approved',
          _stepState(3)),
      if (product.status != _ApprovalStatus.rejected)
        _TimelineStep('Live', _stepState(4)),
    ];

    return Row(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final step = e.value;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (i > 0)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: step.state == _StepState.upcoming
                                  ? AppColors.divider
                                  : (product.status == _ApprovalStatus.rejected &&
                                          i >= 3
                                      ? Colors.red.shade200
                                      : AppColors.primary),
                            ),
                          ),
                        _StepDot(state: step.state,
                            isRejected: product.status == _ApprovalStatus.rejected && i == 3),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: step.state == _StepState.completed
                                  ? (product.status == _ApprovalStatus.rejected && i >= 2
                                      ? Colors.red.shade200
                                      : AppColors.primary)
                                  : AppColors.divider,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(step.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 9,
                            color: step.state == _StepState.upcoming
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontWeight: step.state == _StepState.current
                                ? FontWeight.w700
                                : FontWeight.w400)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  _StepState _stepState(int index) {
    final currentStep = switch (product.status) {
      _ApprovalStatus.draft => 0,
      _ApprovalStatus.pendingReview => 2,
      _ApprovalStatus.approved => 3,
      _ApprovalStatus.rejected => 3,
      _ApprovalStatus.active => 4,
    };
    if (index < currentStep) return _StepState.completed;
    if (index == currentStep) return _StepState.current;
    return _StepState.upcoming;
  }
}

class _StepDot extends StatelessWidget {
  final _StepState state;
  final bool isRejected;
  const _StepDot({required this.state, this.isRejected = false});

  @override
  Widget build(BuildContext context) {
    Color bg;
    IconData? icon;
    if (isRejected && state == _StepState.current) {
      bg = Colors.red;
      icon = Icons.close;
    } else if (state == _StepState.completed) {
      bg = AppColors.primary;
      icon = Icons.check;
    } else if (state == _StepState.current) {
      bg = AppColors.secondary;
      icon = null;
    } else {
      bg = AppColors.divider;
      icon = null;
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: icon != null
          ? Icon(icon, size: 11, color: Colors.white)
          : state == _StepState.current
              ? const Center(child: CircleAvatar(radius: 4, backgroundColor: Colors.white))
              : null,
    );
  }
}

// ── Detail Sheet ──────────────────────────────────────────────────────────────

class _ProductDetailSheet extends StatelessWidget {
  final _ProductSubmission product;
  const _ProductDetailSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2))),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(product.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ),
                      _StatusBadge(status: product.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(product.sku,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 20),
                  _DetailRow('Category', product.category),
                  _DetailRow('Price', 'QAR ${product.price.toStringAsFixed(2)}'),
                  _DetailRow('Images', '${product.images} uploaded'),
                  _DetailRow('Submitted',
                      '${product.submittedAt.day}/${product.submittedAt.month}/${product.submittedAt.year}'),
                  if (product.reviewedAt != null)
                    _DetailRow('Reviewed',
                        '${product.reviewedAt!.day}/${product.reviewedAt!.month}/${product.reviewedAt!.year}'),
                  if (product.reviewerNote != null) ...[
                    const SizedBox(height: 16),
                    const Text('Reviewer Note',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: product.status == _ApprovalStatus.rejected
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: product.status == _ApprovalStatus.rejected
                              ? Colors.red.shade200
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Text(product.reviewerNote!,
                          style: TextStyle(
                              fontSize: 13,
                              color: product.status == _ApprovalStatus.rejected
                                  ? Colors.red.shade800
                                  : Colors.green.shade800)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _ApprovalTimeline(product: product),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _ReviewerNote extends StatelessWidget {
  final String note;
  const _ReviewerNote({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(note,
                style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$count $label',
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _ApprovalStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _ApprovalStatus.draft => ('Draft', AppColors.textSecondary),
      _ApprovalStatus.pendingReview => ('Pending Review', const Color(0xFFF57F17)),
      _ApprovalStatus.approved => ('Approved', const Color(0xFF2E7D32)),
      _ApprovalStatus.rejected => ('Rejected', const Color(0xFFC62828)),
      _ApprovalStatus.active => ('Live', const Color(0xFF1565C0)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────

enum _ApprovalStatus { draft, pendingReview, approved, rejected, active }

enum _StepState { upcoming, current, completed }

class _TimelineStep {
  final String label;
  final _StepState state;
  const _TimelineStep(this.label, this.state);
}

class _ProductSubmission {
  final String id;
  final String name;
  final String sku;
  final String category;
  final double price;
  _ApprovalStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewerNote;
  final int images;

  _ProductSubmission({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.status,
    required this.submittedAt,
    required this.reviewedAt,
    required this.reviewerNote,
    required this.images,
  });
}
