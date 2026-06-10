import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SupplierShipmentTrackingScreen extends StatefulWidget {
  const SupplierShipmentTrackingScreen({super.key});

  @override
  State<SupplierShipmentTrackingScreen> createState() =>
      _SupplierShipmentTrackingScreenState();
}

class _SupplierShipmentTrackingScreenState
    extends State<SupplierShipmentTrackingScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';

  final List<_Shipment> _shipments = [
    _Shipment('SHP-7841', 'PO-4198', 'Aramex', '1234567890', 'out_for_delivery',
        'Doha, Qatar', '9 Jun 2026', [
      _TrackingEvent('Order confirmed', '09 Jun, 9:00 AM'),
      _TrackingEvent('Processing at warehouse', '09 Jun, 11:30 AM'),
      _TrackingEvent('Picked up by Aramex', '09 Jun, 2:00 PM'),
      _TrackingEvent('Out for delivery', '10 Jun, 8:30 AM'),
    ]),
    _Shipment('SHP-7839', 'PO-4185', 'Q Cart Fleet', 'FLEET-0291', 'delivered',
        'Al Rayyan, Qatar', '8 Jun 2026', [
      _TrackingEvent('Order confirmed', '08 Jun, 10:00 AM'),
      _TrackingEvent('Processing at warehouse', '08 Jun, 12:00 PM'),
      _TrackingEvent('Picked up by driver', '08 Jun, 3:00 PM'),
      _TrackingEvent('Out for delivery', '08 Jun, 4:30 PM'),
      _TrackingEvent('Delivered', '08 Jun, 5:15 PM'),
    ]),
    _Shipment('SHP-7830', 'PO-4172', 'Aramex', '9876543210', 'delivered',
        'Al Wakrah, Qatar', '7 Jun 2026', [
      _TrackingEvent('Order confirmed', '07 Jun, 8:00 AM'),
      _TrackingEvent('In transit', '07 Jun, 2:00 PM'),
      _TrackingEvent('Delivered', '07 Jun, 6:00 PM'),
    ]),
    _Shipment('SHP-7820', 'PO-4160', 'DHL', 'DHL-1122334455', 'in_transit',
        'Al Khor, Qatar', '6 Jun 2026', [
      _TrackingEvent('Order confirmed', '06 Jun, 9:00 AM'),
      _TrackingEvent('Picked up by DHL', '06 Jun, 1:00 PM'),
      _TrackingEvent('In transit', '07 Jun, 8:00 AM'),
    ]),
  ];

  List<_Shipment> get _filtered {
    var list = _shipments.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.id.toLowerCase().contains(q) ||
          s.orderId.toLowerCase().contains(q) ||
          s.trackingNo.toLowerCase().contains(q);
    }).toList();
    if (_filterStatus != 'all') {
      list = list.where((s) => s.status == _filterStatus).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Shipment Tracking',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _ShipmentCard(
                      shipment: _filtered[i],
                      onTrack: () => _showTrackingSheet(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search shipment ID or tracking no…',
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

  Widget _buildFilterChips() {
    final filters = [
      ('all', 'All'),
      ('out_for_delivery', 'Out for Delivery'),
      ('in_transit', 'In Transit'),
      ('delivered', 'Delivered'),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((f) {
          final selected = _filterStatus == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.$2,
                  style: TextStyle(
                      color: selected
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13)),
              selected: selected,
              onSelected: (_) => setState(() => _filterStatus = f.$1),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('No shipments found',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _showTrackingSheet(_Shipment shipment) {
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shipment.id,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('${shipment.carrier} · ${shipment.trackingNo}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                  _StatusBadge(shipment.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(shipment.destination,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              const Divider(height: 28),
              const Text('Tracking Timeline',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 15)),
              const SizedBox(height: 16),
              ...shipment.events.asMap().entries.map((entry) {
                final i = entry.key;
                final event = entry.value;
                final isLast = i == shipment.events.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLast
                                ? AppColors.secondary
                                : AppColors.primary,
                          ),
                        ),
                        if (!isLast)
                          Container(
                              width: 2,
                              height: 36,
                              color: AppColors.divider),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.description,
                                style: TextStyle(
                                    fontWeight: isLast
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isLast
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(event.timestamp,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final _Shipment shipment;
  final VoidCallback onTrack;
  const _ShipmentCard({required this.shipment, required this.onTrack});

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(shipment.id,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 15)),
              _StatusBadge(shipment.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.receipt_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(shipment.orderId,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              const Icon(Icons.local_shipping_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(shipment.carrier,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(shipment.destination,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),
              TextButton(
                onPressed: onTrack,
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                child: const Text('Track'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  Color get _color => switch (status) {
        'out_for_delivery' => const Color(0xFF1565C0),
        'in_transit' => const Color(0xFFF57F17),
        'delivered' => const Color(0xFF2E7D32),
        'returned' => Colors.red,
        _ => AppColors.textSecondary,
      };

  String get _label => switch (status) {
        'out_for_delivery' => 'Out for Delivery',
        'in_transit' => 'In Transit',
        'delivered' => 'Delivered',
        'returned' => 'Returned',
        _ => status,
      };

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
              fontSize: 11, fontWeight: FontWeight.w600, color: _color)),
    );
  }
}

class _Shipment {
  final String id, orderId, carrier, trackingNo, status, destination, date;
  final List<_TrackingEvent> events;
  const _Shipment(this.id, this.orderId, this.carrier, this.trackingNo,
      this.status, this.destination, this.date, this.events);
}

class _TrackingEvent {
  final String description, timestamp;
  const _TrackingEvent(this.description, this.timestamp);
}
