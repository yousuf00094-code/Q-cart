import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/parse_num.dart';

class CheckoutScreen extends StatefulWidget {
  final String? couponCode;
  final Map<String, dynamic>? couponData;

  const CheckoutScreen({super.key, this.couponCode, this.couponData});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _loadingAddresses = true;
  bool _loadingCart = true;
  bool _placingOrder = false;

  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _cartData;
  String? _selectedAddressId;
  String _paymentMethod = 'cash_on_delivery';
  String? _couponCode;
  Map<String, dynamic>? _couponData;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _line1Ctrl = TextEditingController();
  final _line2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _couponCode = widget.couponCode;
    _couponData = widget.couponData;
    _loadData();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _line1Ctrl.dispose();
    _line2Ctrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadAddresses(), _loadCart()]);
  }

  Future<void> _loadAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final addresses = await CustomerService.getAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        Map<String, dynamic>? defaultAddr;
        for (final a in addresses) {
          if (a['is_default'] == true) {
            defaultAddr = a;
            break;
          }
        }
        defaultAddr ??= addresses.isNotEmpty ? addresses.first : null;
        if (defaultAddr != null) {
          _selectedAddressId = defaultAddr['id']?.toString();
        }
        _loadingAddresses = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _loadCart() async {
    setState(() => _loadingCart = true);
    try {
      final res = await CartService.getCart();
      if (!mounted) return;
      setState(() {
        _cartData = res['data'] as Map<String, dynamic>?;
        _loadingCart = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCart = false);
    }
  }

  double get _subtotal {
    if (_cartData == null) return 0;
    final val = _cartData!['subtotal'];
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  double get _delivery => _subtotal >= 200 ? 0 : 15;

  double get _discountAmount {
    if (_couponData == null) return 0;
    final type = _couponData!['discount_type']?.toString();
    final value = parseDouble(_couponData!['discount_value']);
    if (type == 'percentage') return (_subtotal * value / 100);
    return value;
  }

  double get _total => _subtotal + _delivery - _discountAmount;

  List<Map<String, dynamic>> get _cartItems {
    if (_cartData == null) return [];
    final items = _cartData!['items'];
    if (items is List) return items.cast<Map<String, dynamic>>();
    return [];
  }

  Future<void> _showAddAddressSheet() async {
    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _line1Ctrl.clear();
    _line2Ctrl.clear();
    _cityCtrl.clear();
    _phoneCtrl.clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _AddAddressSheet(
        formKey: _addressFormKey,
        firstNameCtrl: _firstNameCtrl,
        lastNameCtrl: _lastNameCtrl,
        line1Ctrl: _line1Ctrl,
        line2Ctrl: _line2Ctrl,
        cityCtrl: _cityCtrl,
        phoneCtrl: _phoneCtrl,
        onSaved: () async {
          await _loadAddresses();
        },
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocaleService.t('select_address_hint'))),
      );
      return;
    }

    if (_paymentMethod == 'qpay') {
      Navigator.pushNamed(
        context,
        '/payment',
        arguments: {
          'address_id': _selectedAddressId!,
          'coupon_code': _couponCode,
          'total': _total,
        },
      );
      return;
    }

    setState(() => _placingOrder = true);
    try {
      final order = await CustomerService.placeOrder(
        addressId: _selectedAddressId!,
        paymentMethod: _paymentMethod,
        couponCode: _couponCode,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/order-confirmation', arguments: order);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _placingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : LocaleService.t('error_generic')),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          LocaleService.t('checkout'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(LocaleService.t('delivery_address')),
            const SizedBox(height: 12),
            _buildAddressSection(),
            const SizedBox(height: 20),
            _sectionHeader(LocaleService.t('payment_method')),
            const SizedBox(height: 12),
            _buildPaymentSection(),
            const SizedBox(height: 20),
            _sectionHeader(LocaleService.t('order_summary')),
            const SizedBox(height: 12),
            _buildOrderSummary(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildAddressSection() {
    if (_loadingAddresses) {
      return Column(
        children: List.generate(
          2,
          (_) => Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.divider.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_addresses.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Icon(Icons.location_off_outlined, color: AppColors.textSecondary, size: 36),
                const SizedBox(height: 8),
                Text(
                  LocaleService.t('no_addresses'),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          ..._addresses.map((addr) => _buildAddressCard(addr)),
        OutlinedButton.icon(
          onPressed: _showAddAddressSheet,
          icon: const Icon(Icons.add, size: 18),
          label: Text(LocaleService.t('add_new_address')),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondary,
            side: const BorderSide(color: AppColors.secondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> addr) {
    final id = addr['id']?.toString();
    final isSelected = _selectedAddressId == id;
    final isDefault = addr['is_default'] == true;
    final firstName = addr['first_name']?.toString() ?? '';
    final lastName = addr['last_name']?.toString() ?? '';
    final line1 = addr['address_line1']?.toString() ?? '';
    final line2 = addr['address_line2']?.toString() ?? '';
    final city = addr['city']?.toString() ?? '';
    final label = addr['label']?.toString();

    return GestureDetector(
      onTap: () => setState(() => _selectedAddressId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String?>(
              value: id,
              groupValue: _selectedAddressId,
              onChanged: (v) => setState(() => _selectedAddressId = v),
              activeColor: AppColors.secondary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label ?? '$firstName $lastName',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            LocaleService.t('default_label'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (label != null)
                    Text(
                      '$firstName $lastName',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  Text(line1, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  if (line2.isNotEmpty)
                    Text(line2, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text(city, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      children: [
        _paymentOption(
          value: 'cash_on_delivery',
          icon: Icons.payments_outlined,
          title: LocaleService.t('cash_on_delivery'),
          subtitle: LocaleService.t('cod_subtitle'),
        ),
        const SizedBox(height: 10),
        _paymentOption(
          value: 'qpay',
          icon: Icons.qr_code_scanner,
          title: LocaleService.t('pay_with_qpay'),
          subtitle: LocaleService.t('qpay_subtitle'),
        ),
      ],
    );
  }

  Widget _paymentOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v!),
              activeColor: AppColors.secondary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Icon(icon, color: isSelected ? AppColors.secondary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    if (_loadingCart) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.divider.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._cartItems.map((item) {
            final product = item['product'] as Map<String, dynamic>?;
            final name = product?['name']?.toString() ?? 'Product';
            final price = parseDouble(product?['price']);
            final qty = parseInt(item['quantity'], 1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$name x$qty',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${LocaleService.t('qar')} ${(price * qty).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (_cartItems.isNotEmpty) const Divider(color: AppColors.divider),
          _summaryRow(LocaleService.t('subtotal'), '${LocaleService.t('qar')} ${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _summaryRow(
            LocaleService.t('delivery'),
            _delivery == 0 ? LocaleService.t('free') : '${LocaleService.t('qar')} ${_delivery.toStringAsFixed(2)}',
          ),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 6),
            _summaryRow(
              LocaleService.t('discount'),
              '- ${LocaleService.t('qar')} ${_discountAmount.toStringAsFixed(2)}',
              valueColor: Colors.green.shade600,
            ),
          ],
          const Divider(color: AppColors.divider),
          _summaryRow(
            LocaleService.t('total'),
            '${LocaleService.t('qar')} ${_total.toStringAsFixed(2)}',
            isBold: true,
            valueColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleService.t('total'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Text(
                '${LocaleService.t('qar')} ${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placingOrder ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: AppColors.secondary.withOpacity(0.6),
              ),
              child: _placingOrder
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _paymentMethod == 'qpay'
                          ? LocaleService.t('pay_with_qpay')
                          : LocaleService.t('place_order'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAddressSheet extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController line1Ctrl;
  final TextEditingController line2Ctrl;
  final TextEditingController cityCtrl;
  final TextEditingController phoneCtrl;
  final Future<void> Function() onSaved;

  const _AddAddressSheet({
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.line1Ctrl,
    required this.line2Ctrl,
    required this.cityCtrl,
    required this.phoneCtrl,
    required this.onSaved,
  });

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  bool _saving = false;

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? LocaleService.t('error_generic') : null
          : null,
    );
  }

  Future<void> _submit() async {
    if (!widget.formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await CustomerService.createAddress({
        'first_name': widget.firstNameCtrl.text.trim(),
        'last_name': widget.lastNameCtrl.text.trim(),
        'address_line1': widget.line1Ctrl.text.trim(),
        if (widget.line2Ctrl.text.trim().isNotEmpty)
          'address_line2': widget.line2Ctrl.text.trim(),
        'city': widget.cityCtrl.text.trim(),
        if (widget.phoneCtrl.text.trim().isNotEmpty)
          'phone': widget.phoneCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context);
      await widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : LocaleService.t('error_generic'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: widget.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocaleService.t('add_new_address'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _field(widget.firstNameCtrl, LocaleService.t('first_name'), required: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(widget.lastNameCtrl, LocaleService.t('last_name'), required: true)),
                ],
              ),
              const SizedBox(height: 12),
              _field(widget.line1Ctrl, LocaleService.t('address_line1'), required: true),
              const SizedBox(height: 12),
              _field(widget.line2Ctrl, LocaleService.t('address_line2')),
              const SizedBox(height: 12),
              _field(widget.cityCtrl, LocaleService.t('city'), required: true),
              const SizedBox(height: 12),
              _field(widget.phoneCtrl, LocaleService.t('phone'), keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(LocaleService.t('save')),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
