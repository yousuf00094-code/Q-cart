import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SupplierRatingsScreen extends StatefulWidget {
  const SupplierRatingsScreen({super.key});

  @override
  State<SupplierRatingsScreen> createState() => _SupplierRatingsScreenState();
}

class _SupplierRatingsScreenState extends State<SupplierRatingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _filterRating = 'all';

  final List<_Review> _reviews = [
    _Review('Ahmed Al-Mansouri', 5, 'Wireless Earbuds Pro',
        'Excellent quality! Fast shipping and well packed. Would buy again.',
        '8 Jun 2026', true),
    _Review('Sara Hassan', 4, 'Mechanical Keyboard',
        'Great keyboard. The click sound is satisfying. Packaging was solid.',
        '7 Jun 2026', false),
    _Review('Mohammed Al-Qahtani', 5, 'USB-C Hub 7-in-1',
        'Works perfectly with my MacBook. All ports functioning.',
        '6 Jun 2026', true),
    _Review('Fatima Al-Farsi', 3, 'Webcam 1080p',
        'Average quality. The image is good in daylight but poor at night.',
        '5 Jun 2026', false),
    _Review('Khalid Al-Dosari', 2, 'Mouse Pad XL',
        'Took longer than expected. The surface quality is not as advertised.',
        '4 Jun 2026', false),
    _Review('Noura Al-Thani', 5, 'Laptop Stand Aluminium',
        'Perfect! Very sturdy and looks premium. Highly recommend.',
        '3 Jun 2026', true),
  ];

  final Map<int, int> _ratingBreakdown = {5: 62, 4: 18, 3: 12, 2: 5, 1: 3};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<_Review> get _filtered {
    if (_filterRating == 'all') return _reviews;
    final rating = int.parse(_filterRating);
    return _reviews.where((r) => r.rating == rating).toList();
  }

  double get _avgRating {
    int total = 0;
    int count = 0;
    _ratingBreakdown.forEach((stars, qty) {
      total += stars * qty;
      count += qty;
    });
    return count > 0 ? total / count : 0;
  }

  int get _totalReviews =>
      _ratingBreakdown.values.fold(0, (sum, v) => sum + v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Ratings & Reviews',
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
          tabs: const [
            Tab(text: 'Reviews'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildReviewsTab(),
          _buildSummaryTab(),
        ],
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
                      Icon(Icons.star_border,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.4)),
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
              Text(
                _avgRating.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              _StarRow(_avgRating),
              const SizedBox(height: 4),
              Text('$_totalReviews reviews',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
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
                      Text('$stars',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          size: 12, color: Color(0xFFFFB300)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor:
                                const Color(0xFFFFB300).withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFB300)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 24,
                        child: Text('$count',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
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
              label: Text(
                o == 'all' ? 'All' : '$o ★',
                style: TextStyle(
                    color: selected
                        ? AppColors.secondary
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13),
              ),
              selected: selected,
              onSelected: (_) => setState(() => _filterRating = o),
              selectedColor: AppColors.secondary.withOpacity(0.15),
              backgroundColor: AppColors.background,
              checkmarkColor: AppColors.secondary,
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

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPerformanceBadges(),
          const SizedBox(height: 16),
          _buildKeywordCloud(),
          const SizedBox(height: 16),
          _buildReplyRateCard(),
        ],
      ),
    );
  }

  Widget _buildPerformanceBadges() {
    final badges = [
      ('Top Rated Seller', Icons.workspace_premium, const Color(0xFFFFB300),
          'Avg. rating ≥ 4.5'),
      ('Fast Shipper', Icons.local_shipping_outlined,
          const Color(0xFF1565C0), '95% on-time delivery'),
      ('Responsive', Icons.message_outlined, const Color(0xFF2E7D32),
          '92% reply rate'),
    ];
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
          const Text('Performance Badges',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15)),
          const SizedBox(height: 14),
          ...badges.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: b.$3.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(b.$2, color: b.$3, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.$1,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          Text(b.$4,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 20),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildKeywordCloud() {
    final keywords = [
      ('Great quality', 28),
      ('Fast delivery', 24),
      ('Well packed', 19),
      ('As described', 16),
      ('Highly recommend', 14),
      ('Good value', 11),
      ('Slow shipping', 4),
      ('Poor packaging', 3),
    ];
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
          const Text('Common Review Keywords',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: keywords.map((k) {
              final isNegative =
                  k.$1.contains('Slow') || k.$1.contains('Poor');
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isNegative
                      ? Colors.red.withOpacity(0.08)
                      : const Color(0xFF2E7D32).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(k.$1,
                        style: TextStyle(
                            fontSize: 13,
                            color: isNegative
                                ? Colors.red
                                : const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    Text('${k.$2}',
                        style: TextStyle(
                            fontSize: 11,
                            color: isNegative
                                ? Colors.red.withOpacity(0.7)
                                : const Color(0xFF2E7D32).withOpacity(0.7))),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyRateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.forum_outlined, color: AppColors.secondary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reply Rate: 92%',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 15)),
                SizedBox(height: 2),
                Text(
                    'Responding to reviews improves trust and ranking. 8 unanswered.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReplySheet(_Review review) {
    final replyCtrl = TextEditingController();
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
            const Text('Reply to Review',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('"${review.comment}"',
                  style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                      fontSize: 13)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Write your reply…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => review.hasReply = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reply posted successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Post Reply',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
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
                child: Text(
                  review.reviewer[0],
                  style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewer,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(review.product,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StarRow(review.rating.toDouble()),
                  const SizedBox(height: 2),
                  Text(review.date,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.comment,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
          if (review.isVerified) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.verified_outlined,
                    size: 14, color: Color(0xFF2E7D32)),
                SizedBox(width: 4),
                Text('Verified Purchase',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF2E7D32))),
              ],
            ),
          ],
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
                  Icon(Icons.store_rounded,
                      size: 14, color: AppColors.secondary),
                  SizedBox(width: 6),
                  Text('You replied to this review',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
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
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
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
  final String reviewer, product, comment, date;
  final int rating;
  final bool isVerified;
  bool hasReply;

  _Review(this.reviewer, this.rating, this.product, this.comment, this.date,
      this.hasReply,
      {this.isVerified = true});
}
