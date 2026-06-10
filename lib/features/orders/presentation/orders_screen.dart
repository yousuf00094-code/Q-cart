import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const List<_Order> _active = [
    _Order(
      id: '#QC-20481',
      date: 'Today, 10:30 AM',
      items: 3,
      total: 183.00,
      status: _OrderStatus.outForDelivery,
      steps: 3,
    ),
    _Order(
      id: '#QC-20475',
      date: 'Yesterday, 2:15 PM',
      items: 1,
      total: 120.00,
      status: _OrderStatus.processing,
      steps: 1,
    ),
  ];

  static const List<_Order> _previous = [
    _Order(
      id: '#QC-20451',
      date: 'Jun 5, 2026',
      items: 5,
      total: 342.50,
      status: _OrderStatus.delivered,
      steps: 4,
    ),
    _Order(
      id: '#QC-20430',
      date: 'May 28, 2026',
      items: 2,
      total: 63.00,
      status: _OrderStatus.delivered,
      steps: 4,
    ),
    _Order(
      id: '#QC-20418',
      date: 'May 20, 2026',
      items: 4,
      total: 210.00,
      status: _OrderStatus.cancelled,
      steps: 1,
    ),
  ];

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
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(3),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Active'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_active.length}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const Tab(text: 'Previous'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrderList(orders: _active, showTracking: true),
          _OrderList(orders: _previous, showTracking: false),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders, required this.showTracking});

  final List<_Order> orders;
  final bool showTracking;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 56, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _OrderCard(
        order: orders[i],
        showTracking: showTracking,
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.order, required this.showTracking});

  final _Order order;
  final bool showTracking;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _trackingExpanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.id,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    _StatusChip(status: order.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      order.date,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.shopping_bag_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${order.items} item${order.items > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QAR ${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                    Row(
                      children: [
                        if (order.status == _OrderStatus.delivered) ...[
                          _ActionButton(
                            label: 'Reorder',
                            icon: Icons.refresh,
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.showTracking)
                          _ActionButton(
                            label: _trackingExpanded ? 'Hide' : 'Track',
                            icon: Icons.location_on_outlined,
                            filled: true,
                            onTap: () => setState(
                                () => _trackingExpanded = !_trackingExpanded),
                          ),
                        if (!widget.showTracking &&
                            order.status != _OrderStatus.delivered)
                          _ActionButton(
                            label: 'Details',
                            icon: Icons.info_outline,
                            onTap: () {},
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.showTracking && _trackingExpanded) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _TrackingTimeline(order: order),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline({required this.order});

  final _Order order;

  static const _steps = [
    (Icons.check_circle_outline, 'Order Placed', 'Your order has been confirmed'),
    (Icons.inventory_2_outlined, 'Processing', 'Preparing your items'),
    (Icons.local_shipping_outlined, 'Out for Delivery', 'On the way to you'),
    (Icons.home_outlined, 'Delivered', 'Enjoy your order!'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Tracking',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_steps.length, (i) {
          final (icon, title, subtitle) = _steps[i];
          final isDone = i < order.steps;
          final isLast = i == _steps.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.secondary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDone ? AppColors.secondary : AppColors.divider,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: isDone ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 36,
                      color: isDone
                          ? AppColors.secondary.withOpacity(0.3)
                          : AppColors.divider,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      SizedBox(height: isLast ? 0 : 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      _OrderStatus.processing => ('Processing', const Color(0xFFFFF3E0), const Color(0xFFF57C00)),
      _OrderStatus.outForDelivery => ('Out for Delivery', const Color(0xFFE3F2FD), const Color(0xFF1976D2)),
      _OrderStatus.delivered => ('Delivered', const Color(0xFFE8F5E9), const Color(0xFF388E3C)),
      _OrderStatus.cancelled => ('Cancelled', const Color(0xFFFFE8E8), const Color(0xFFE53935)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? AppColors.secondary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: filled ? AppColors.secondary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: filled ? Colors.white : AppColors.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OrderStatus { processing, outForDelivery, delivered, cancelled }

class _Order {
  final String id;
  final String date;
  final int items;
  final double total;
  final _OrderStatus status;
  final int steps;

  const _Order({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.status,
    required this.steps,
  });
}
