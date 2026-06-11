import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supplier_service.dart';
import '../../../core/services/api_client.dart';

class SupplierRatingsScreen extends StatefulWidget {
  const SupplierRatingsScreen({super.key});

  @override
  State<SupplierRatingsScreen> createState() => _SupplierRatingsScreenState();
}

class _SupplierRatingsScreenState extends State<SupplierRatingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _filterRating = 'all';

  List<_Review>? _reviews;
  Map<int, int> _ratingBreakdown = {};
  double _avgRatingValue = 0;
  int _totalReviews = 0;
  int _pendingReply = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        SupplierService.getRatingsSummary(),
        SupplierService.getRatings(
          page: 1,
          rating: _filterRating == 'all' ? null : int.tryParse(_filterRating),
        ),
      ]);
      if (!mounted) return;
      final summary = results[0] as Map<String, dynamic>;
      final ratingsRes = results[1] as Map<String, dynamic>;
      final data = ratingsRes['data'] as List<dynamic>? ?? [];

      setState(() {
        _avgRatingValue = double.tryParse(summary['avg_rating']?.toString() ?? '0') ?? 0;
        _totalReviews = int.tryParse(summary['total_reviews']?.toString() ?? '0') ?? 0;
        _pendingReply = int.tryParse(summary['pending_reply_count']?.toString() ?? '0') ?? 0;
        _ratingBreakdown = {
          5: int.tryParse(summary['five_star']?.toString() ?? '0') ?? 0,
          4: int.tryParse(summary['four_star']?.toString() ?? '0') ?? 0,
          3: int.tryParse(summary['three_star']?.toString() ?? '0') ?? 0,
          2: int.tryParse(summary['two_star']?.toString() ?? '0') ?? 0,
          1: int.tryParse(summary['one_star']?.toString() ?? '0') ?? 0,
        };
        _reviews = data.map((r) {
          final m = r as Map<String, dynamic>;
          return _Review(
            id: m['id']?.toString() ?? '',
            reviewer: m['reviewer_name']?.toString() ?? 'Anonymous',
            rating: int.tryParse(m['rating']?.toString() ?? '0') ?? 0,
            product: m['product_name']?.toString() ?? '',
            comment: m['comment']?.toString() ?? '',
            date: _formatDate(m['created_at']?.toString() ?? ''),
            hasReply: m['reply'] != null,
          );
        }).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load reviews. Pull down to retry.'; _loading = false; });
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso) ?? DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  List<_Review> get _filtered {
    final list = _reviews ?? [];
    if (_filterRating == 'all') return list;
    final rating = int.tryParse(_filterRating);
    if (rating == null) return list;
    return list.where((r) => r.rating == rating).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Ratings & Reviews',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          tabs: const [Tab(text: 'Reviews'), Tab(text: 'Summary')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [_buildReviewsTab(), _buildSummaryTab()],
                  ),
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

  Widget _buildReviewsTab() {
    return Column(
      children: [
        _buildRatingSummaryCard(),
        _buildRatingFilter(),
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_border, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      const Text('No reviews for this filter',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _ReviewCard(
                    review: _filtered[i],
                    onReply: () => _showReplySheet(_filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRatingSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(_avgRatingValue.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              _StarRow(_avgRatingValue),
              const SizedBox(height: 4),
              Text('$_totalReviews reviews',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((stars) {
                final count = _ratingBreakdown[stars] ?? 0;
                final pct = _totalReviews > 0 ? count / _totalReviews : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text('$stars', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB300)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFFFB300).withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 24,
                        child: Text('$count',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingFilter() {
    final options = ['all', '5', '4', '3', '2', '1'];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: options.map((o) {
          final selected = _filterRating == o;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(o == 'all' ? 'All' : '$o ★',
                  style: TextStyle(
                      color: selected ? AppColors.secondary : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13)),
              selected: selected,
              onSelected: (_) {
                setState(() => _filterRating = o);
                _fetchData();
              },
              selectedColor: AppColors.secondary.withOpacity(0.15),
              backgroundColor: AppColors.background,
              checkmarkColor: AppColors.secondary,
              side: BorderSide(color: selected ? AppColors.secondary.withOpacity(0.4) : AppColors.divider),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryTab() {
    final repliedCount = _totalReviews - _pendingReply;
    final replyRate = _totalReviews > 0 ? (repliedCount / _totalReviews * 100).toStringAsFixed(0) : '0';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Performance Overview',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15)),
                const SizedBox(height: 14),
                _StatRow('Average Rating', '${_avgRatingValue.toStringAsFixed(1)} / 5.0'),
                _StatRow('Total Reviews', '$_totalReviews'),
                _StatRow('Replied', '$repliedCount'),
                _StatRow('Pending Reply', '$_pendingReply'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2), shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.forum_outlined, color: AppColors.secondary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reply Rate: $replyRate%',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('$_pendingReply unanswered review${_pendingReply == 1 ? '' : 's'}.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReplySheet(_Review review) {
    final replyCtrl = TextEditingController();
    bool submitting = false;
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
              const Text('Reply to Review',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                child: Text('"${review.comment}"',
                    style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary, fontSize: 13)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: replyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Write your reply…', alignLabelWithHint: true),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: submitting ? null : () async {
                    if (replyCtrl.text.trim().isEmpty) return;
                    setModal(() => submitting = true);
                    try {
                      await SupplierService.replyToReview(review.id, replyCtrl.text.trim());
                      if (!context.mounted) return;
                      Navigator.pop(ctx);
                      setState(() => review.hasReply = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reply posted successfully'), behavior: SnackBarBehavior.floating),
                      );
                    } catch (_) {
                      setModal(() => submitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to post reply'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Post Reply', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final _Review review;
  final VoidCallback onReply;
  const _ReviewCard({required this.review, required this.onReply});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.secondary.withOpacity(0.15),
                child: Text(review.reviewer.isNotEmpty ? review.reviewer[0] : '?',
                    style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewer, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(review.product, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StarRow(review.rating.toDouble()),
                  const SizedBox(height: 2),
                  Text(review.date, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.comment,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 10),
          if (review.hasReply)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.store_rounded, size: 14, color: AppColors.secondary),
                  SizedBox(width: 6),
                  Text('You replied to this review',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            )
          else
            TextButton.icon(
              onPressed: onReply,
              icon: const Icon(Icons.reply_outlined, size: 16),
              label: const Text('Reply'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow(this.rating);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating.floor()
              ? Icons.star_rounded
              : (i < rating ? Icons.star_half_rounded : Icons.star_outline_rounded),
          color: const Color(0xFFFFB300),
          size: 16,
        );
      }),
    );
  }
}

class _Review {
  final String id, reviewer, product, comment, date;
  final int rating;
  bool hasReply;

  _Review({
    required this.id,
    required this.reviewer,
    required this.rating,
    required this.product,
    required this.comment,
    required this.date,
    required this.hasReply,
  });
}
