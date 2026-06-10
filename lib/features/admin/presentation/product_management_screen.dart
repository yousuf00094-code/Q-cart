import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  static final List<_Product> _products = [
    _Product(id: 'P001', name: 'Organic Dates 500g', sku: 'GR-DATES-500',
        category: 'Groceries', price: 35.0, compareAt: 45.0, stock: 78, rating: 4.5, isActive: true, isFeatured: true),
    _Product(id: 'P002', name: 'Saffron Pack 5g', sku: 'GR-SAFFRON-5',
        category: 'Groceries', price: 120.0, compareAt: null, stock: 6, rating: 4.2, isActive: true, isFeatured: false),
    _Product(id: 'P003', name: 'iPhone 15 128GB', sku: 'EL-IPHN-15',
        category: 'Electronics', price: 3800.0, compareAt: 4200.0, stock: 9, rating: 4.8, isActive: true, isFeatured: true),
    _Product(id: 'P004', name: 'Camel Milk 1L', sku: 'DA-CAMEL-1L',
        category: 'Dairy', price: 28.0, compareAt: null, stock: 27, rating: 3.9, isActive: true, isFeatured: false),
    _Product(id: 'P005', name: 'Oud Perfume 50ml', sku: 'BE-OUD-50',
        category: 'Beauty', price: 250.0, compareAt: 320.0, stock: 0, rating: 4.7, isActive: true, isFeatured: true),
    _Product(id: 'P006', name: 'Premium Yoga Mat', sku: 'SP-YOGA-MAT',
        category: 'Sports', price: 180.0, compareAt: null, stock: 16, rating: 4.1, isActive: false, isFeatured: false),
    _Product(id: 'P007', name: 'Sidr Honey 500g', sku: 'GR-HONEY-500',
        category: 'Groceries', price: 85.0, compareAt: 100.0, stock: 51, rating: 4.6, isActive: true, isFeatured: false),
    _Product(id: 'P008', name: 'Rose Water 250ml', sku: 'BE-ROSEWATER',
        category: 'Beauty', price: 22.0, compareAt: null, stock: 0, rating: 3.7, isActive: false, isFeatured: false),
  ];

  static final _categories = ['All', ..._products.map((p) => p.category).toSet().toList()..sort()];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _selectedCategory = 'All';
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Product> _filtered(bool? activeFilter) {
    return _products.where((p) {
      final matchQuery = _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          p.sku.toLowerCase().contains(_query.toLowerCase());
      final matchCat = _selectedCategory == null || _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchActive = activeFilter == null || p.isActive == activeFilter;
      return matchQuery && matchCat && matchActive;
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
        title: const Text('Products',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
            onPressed: () => _showProductSheet(context, null),
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
              tabs: const [Tab(text: 'All'), Tab(text: 'Active'), Tab(text: 'Inactive')],
            ),
          ),
        ),
      ),
      body: Column(children: [
        _buildSearch(),
        _buildCategoryFilter(),
        _buildProductCounts(),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _ProductList(products: _filtered(null), onEdit: (p) => _showProductSheet(context, p), onToggle: _toggleActive),
              _ProductList(products: _filtered(true), onEdit: (p) => _showProductSheet(context, p), onToggle: _toggleActive),
              _ProductList(products: _filtered(false), onEdit: (p) => _showProductSheet(context, p), onToggle: _toggleActive),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search products or SKU…',
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
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: _categories.map((c) => GestureDetector(
          onTap: () => setState(() => _selectedCategory = c),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _selectedCategory == c ? AppColors.secondary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _selectedCategory == c ? AppColors.secondary : AppColors.divider),
            ),
            child: Text(c, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: _selectedCategory == c ? Colors.white : AppColors.textSecondary,
            )),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildProductCounts() {
    final active = _products.where((p) => p.isActive).length;
    final featured = _products.where((p) => p.isFeatured).length;
    final oos = _products.where((p) => p.stock == 0).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(children: [
        _Pill('${_products.length} Total', AppColors.surface, AppColors.textPrimary),
        const SizedBox(width: 8),
        _Pill('$active Active', const Color(0xFFE8F5E9), const Color(0xFF388E3C)),
        const SizedBox(width: 8),
        _Pill('$featured Featured', const Color(0xFFFFF3E0), const Color(0xFFF57C00)),
        const SizedBox(width: 8),
        if (oos > 0) _Pill('$oos OOS', const Color(0xFFFFE8E8), const Color(0xFFE53935)),
      ]),
    );
  }

  void _toggleActive(_Product p) {
    setState(() {
      final idx = _products.indexWhere((x) => x.id == p.id);
      if (idx >= 0) _products[idx] = _products[idx].copyWith(isActive: !_products[idx].isActive);
    });
  }

  void _showProductSheet(BuildContext context, _Product? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormSheet(existing: existing),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products, required this.onEdit, required this.onToggle});
  final List<_Product> products;
  final void Function(_Product) onEdit;
  final void Function(_Product) onToggle;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondary),
          SizedBox(height: 10),
          Text('No products found', style: TextStyle(color: AppColors.textSecondary)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ProductCard(product: products[i], onEdit: onEdit, onToggle: onToggle),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onEdit, required this.onToggle});
  final _Product product;
  final void Function(_Product) onEdit;
  final void Function(_Product) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: product.isActive ? AppColors.surface : AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_basket_outlined, size: 26, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(product.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (product.isFeatured)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Featured', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFF57C00))),
                  ),
              ]),
              const SizedBox(height: 2),
              Text('${product.sku} · ${product.category}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Row(children: [
                Text('QAR ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                if (product.compareAt != null) ...[
                  const SizedBox(width: 6),
                  Text('QAR ${product.compareAt!.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.6),
                          decoration: TextDecoration.lineThrough)),
                ],
              ]),
            ])),
          ]),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            _ChipInfo(Icons.inventory_2_outlined, '${product.stock} in stock',
                product.stock == 0 ? const Color(0xFFE53935) : product.stock <= 10 ? const Color(0xFFF57C00) : const Color(0xFF388E3C)),
            const SizedBox(width: 8),
            _ChipInfo(Icons.star, product.rating.toStringAsFixed(1), const Color(0xFFFFC107)),
            const Spacer(),
            GestureDetector(
              onTap: () => onToggle(product),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: product.isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFE8E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(product.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: product.isActive ? const Color(0xFF388E3C) : const Color(0xFFE53935),
                    )),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onEdit(product),
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
        ),
      ]),
    );
  }
}

class _ProductFormSheet extends StatelessWidget {
  const _ProductFormSheet({this.existing});
  final _Product? existing;

  @override
  Widget build(BuildContext context) {
    final isEdit = existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
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
            Text(isEdit ? 'Edit Product' : 'Add Product',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _FormField('Product Name', existing?.name),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _FormField('SKU', existing?.sku)),
              const SizedBox(width: 12),
              Expanded(child: _FormField('Category', existing?.category)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _FormField('Price (QAR)', existing?.price.toStringAsFixed(2))),
              const SizedBox(width: 12),
              Expanded(child: _FormField('Compare At Price', existing?.compareAt?.toStringAsFixed(2))),
            ]),
            const SizedBox(height: 12),
            _FormField('Description', null, maxLines: 4),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _FormField('Weight (grams)', null)),
              const SizedBox(width: 12),
              Expanded(child: _FormField('Barcode', null)),
            ]),
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
                child: Text(isEdit ? 'Save Changes' : 'Add Product',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Small widgets ─────────────────────────────────────────────────────────

class _ChipInfo extends StatelessWidget {
  const _ChipInfo(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.bg, this.fg);
  final String label;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField(this.label, this.initial, {this.maxLines = 1});
  final String label;
  final String? initial;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initial,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }
}

// ─── Data class ────────────────────────────────────────────────────────────

class _Product {
  final String id, name, sku, category;
  final double price;
  final double? compareAt;
  final int stock;
  final double rating;
  final bool isActive, isFeatured;

  const _Product({
    required this.id, required this.name, required this.sku,
    required this.category, required this.price, this.compareAt,
    required this.stock, required this.rating,
    required this.isActive, required this.isFeatured,
  });

  _Product copyWith({bool? isActive}) => _Product(
    id: id, name: name, sku: sku, category: category,
    price: price, compareAt: compareAt, stock: stock, rating: rating,
    isActive: isActive ?? this.isActive, isFeatured: isFeatured,
  );
}
