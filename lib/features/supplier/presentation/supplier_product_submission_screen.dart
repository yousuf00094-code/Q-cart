import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supplier_service.dart';
import '../../../core/services/api_client.dart';

class SupplierProductSubmissionScreen extends StatefulWidget {
  const SupplierProductSubmissionScreen({super.key});

  @override
  State<SupplierProductSubmissionScreen> createState() =>
      _SupplierProductSubmissionScreenState();
}

class _SupplierProductSubmissionScreenState
    extends State<SupplierProductSubmissionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _submitError;

  // Basic Info
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCategoryId = '';

  // Pricing
  final _priceCtrl = TextEditingController();
  final _comparePriceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  // Inventory
  final _stockCtrl = TextEditingController();
  final _reorderCtrl = TextEditingController();
  bool _trackInventory = true;

  // Shipping
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  // Categories loaded from API
  List<Map<String, dynamic>> _categories = [];
  bool _catLoading = true;

  final List<String> _imageUrls = [];
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose(); _skuCtrl.dispose(); _descCtrl.dispose();
    _priceCtrl.dispose(); _comparePriceCtrl.dispose(); _costCtrl.dispose();
    _stockCtrl.dispose(); _reorderCtrl.dispose();
    _weightCtrl.dispose(); _lengthCtrl.dispose();
    _widthCtrl.dispose(); _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await SupplierService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _catLoading = false;
        if (cats.isNotEmpty) {
          _selectedCategoryId = cats[0]['id']?.toString() ?? '';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _catLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId.isEmpty) {
      setState(() => _submitError = 'Please select a category.');
      return;
    }
    setState(() { _submitting = true; _submitError = null; });

    try {
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'category_id': _selectedCategoryId,
        'price': double.parse(_priceCtrl.text.trim()),
        'description': _descCtrl.text.trim(),
        if (_skuCtrl.text.trim().isNotEmpty) 'sku': _skuCtrl.text.trim(),
        if (_comparePriceCtrl.text.trim().isNotEmpty)
          'compare_at_price': double.tryParse(_comparePriceCtrl.text.trim()),
        if (_costCtrl.text.trim().isNotEmpty)
          'cost_price': double.tryParse(_costCtrl.text.trim()),
        if (_trackInventory && _stockCtrl.text.trim().isNotEmpty)
          'stock_quantity': int.tryParse(_stockCtrl.text.trim()) ?? 0,
        if (_trackInventory && _reorderCtrl.text.trim().isNotEmpty)
          'reorder_point': int.tryParse(_reorderCtrl.text.trim()),
        if (_weightCtrl.text.trim().isNotEmpty)
          'weight_grams': ((double.tryParse(_weightCtrl.text.trim()) ?? 0) * 1000).round(),
        if (_imageUrls.isNotEmpty) 'images': _imageUrls,
        'is_active': false,
      };

      await SupplierService.submitProduct(data);
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSuccessSheet();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _submitting = false; _submitError = e.message; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _submitting = false; _submitError = 'Failed to submit. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Submit Product',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Save Draft',
                style: TextStyle(color: AppColors.secondary)),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Pricing'),
            Tab(text: 'Inventory'),
            Tab(text: 'Shipping'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_submitError != null)
              Container(
                width: double.infinity,
                color: Colors.red.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(_submitError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildBasicInfoTab(),
                  _buildPricingTab(),
                  _buildInventoryTab(),
                  _buildShippingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageUploadSection(),
          const SizedBox(height: 20),
          _buildSection('Product Details', [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  prefixIcon: Icon(Icons.inventory_2_outlined)),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _skuCtrl,
              decoration: const InputDecoration(
                  labelText: 'SKU / Barcode',
                  prefixIcon: Icon(Icons.qr_code_outlined)),
            ),
            const SizedBox(height: 14),
            _catLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
                    decoration: const InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: Icon(Icons.category_outlined)),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                              value: c['id']?.toString() ?? '',
                              child: Text(c['name']?.toString() ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCategoryId = v);
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
            const SizedBox(height: 14),
            TextFormField(
              decoration: const InputDecoration(
                  labelText: 'Brand',
                  prefixIcon: Icon(Icons.branding_watermark_outlined)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description *',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  v == null || v.length < 20 ? 'Min. 20 characters' : null,
            ),
          ]),
          const SizedBox(height: 20),
          _buildTagsSection(),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    if (_imageUrls.length >= 8) return;
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (file == null) return;
    setState(() => _uploadingImage = true);
    try {
      final url = await SupplierService.uploadImage(file.path);
      if (!mounted) return;
      setState(() => _imageUrls.add(url));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image upload failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Images',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Add up to 8 images. First image is the cover.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._imageUrls.asMap().entries.map((e) => _buildImageThumbnail(e.value, e.key)),
              if (_imageUrls.length < 8) _buildAddImageTile(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(String url, int index) {
    return Container(
      width: 88,
      height: 88,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined, color: AppColors.primary, size: 32)),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _imageUrls.removeAt(index)),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.8),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: const Text('Cover',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddImageTile() {
    return GestureDetector(
      onTap: _uploadingImage ? null : _pickAndUploadImage,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.divider, style: BorderStyle.solid, width: 1.5),
        ),
        child: _uploadingImage
            ? const Center(
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)))
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.textSecondary, size: 28),
                  SizedBox(height: 4),
                  Text('Add',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
      ),
    );
  }

  Widget _buildTagsSection() {
    final tags = ['Electronics', 'Wireless', 'Bluetooth', 'Audio'];
    return _buildSection('Tags & Attributes', [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...tags.map((t) => Chip(
                label: Text(t, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.primary.withOpacity(0.15),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {},
              )),
          ActionChip(
            label: const Text('+ Add Tag',
                style: TextStyle(fontSize: 12, color: AppColors.secondary)),
            backgroundColor: AppColors.secondary.withOpacity(0.08),
            onPressed: () {},
          ),
        ],
      ),
    ]);
  }

  Widget _buildPricingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection('Pricing', [
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Selling Price (QAR) *',
                prefixIcon: Icon(Icons.sell_outlined),
                prefixText: 'QAR ',
              ),
              validator: (v) =>
                  v == null || double.tryParse(v) == null ? 'Enter valid price' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _comparePriceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Compare-at Price (original)',
                prefixIcon: Icon(Icons.price_change_outlined),
                prefixText: 'QAR ',
                helperText: 'Shown as strikethrough price',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _costCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cost Price (QAR)',
                prefixIcon: Icon(Icons.monetization_on_outlined),
                prefixText: 'QAR ',
                helperText: 'Not visible to customers',
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('VAT', [
            SwitchListTile(
              title: const Text('Apply 5% VAT',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
              subtitle: const Text(
                  'Required for goods sold in Qatar per Jan 2024 VAT law',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.secondary,
              contentPadding: EdgeInsets.zero,
            ),
          ]),
          const SizedBox(height: 20),
          _buildMarginCard(),
        ],
      ),
    );
  }

  Widget _buildMarginCard() {
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final commission = price * 0.10;
    final vat = price * 0.05;
    final payout = price - commission - vat;
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
          const Text('Profit Estimate',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...[
            ('Selling Price', 'QAR ${price.toStringAsFixed(2)}'),
            ('Q Cart Commission (10%)', '- QAR ${commission.toStringAsFixed(2)}'),
            ('VAT (5%)', '- QAR ${vat.toStringAsFixed(2)}'),
            ('Your Estimated Payout', 'QAR ${payout.toStringAsFixed(2)}'),
          ].map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.$1,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  Text(r.$2,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection('Stock Management', [
            SwitchListTile(
              title: const Text('Track Inventory',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
              value: _trackInventory,
              onChanged: (v) => setState(() => _trackInventory = v),
              activeColor: AppColors.secondary,
              contentPadding: EdgeInsets.zero,
            ),
            if (_trackInventory) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial Stock Quantity *',
                  prefixIcon: Icon(Icons.inventory_outlined),
                ),
                validator: (v) => _trackInventory &&
                        (v == null || int.tryParse(v) == null)
                    ? 'Enter quantity'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _reorderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reorder Point',
                  prefixIcon: Icon(Icons.refresh_outlined),
                  helperText:
                      'You\'ll be alerted when stock drops below this',
                ),
              ),
            ],
          ]),
          const SizedBox(height: 20),
          _buildSection('Availability', [
            SwitchListTile(
              title: const Text('Allow Backorders',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
              subtitle: const Text(
                  'Customers can order even when out of stock',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              value: false,
              onChanged: (_) {},
              activeColor: AppColors.secondary,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Set Stock Alert',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
              subtitle: const Text('Email me when stock is low',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.secondary,
              contentPadding: EdgeInsets.zero,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildShippingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection('Package Dimensions', [
            TextFormField(
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                prefixIcon: Icon(Icons.scale_outlined),
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lengthCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Length (cm)', suffixText: 'cm'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _widthCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Width (cm)', suffixText: 'cm'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Height (cm)', suffixText: 'cm'),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('Handling', [
            DropdownButtonFormField<String>(
              value: '1-2 business days',
              decoration: const InputDecoration(
                  labelText: 'Processing Time',
                  prefixIcon: Icon(Icons.schedule_outlined)),
              items: [
                'Same day',
                '1-2 business days',
                '3-5 business days',
                '1 week+'
              ]
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (_) {},
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              title: const Text('Requires Fragile Handling',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
              value: false,
              onChanged: (_) {},
              activeColor: AppColors.secondary,
              contentPadding: EdgeInsets.zero,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (_tabCtrl.index > 0) {
                  _tabCtrl.animateTo(_tabCtrl.index - 1);
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _submitting
                  ? null
                  : () {
                      if (_tabCtrl.index < 3) {
                        _tabCtrl.animateTo(_tabCtrl.index + 1);
                      } else {
                        _submit();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _tabCtrl.index < 3 ? 'Next' : 'Submit for Approval',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline,
                  color: Color(0xFF2E7D32), size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Product Submitted!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'Your product is under review. Approval typically takes 24–48 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back to Dashboard',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
