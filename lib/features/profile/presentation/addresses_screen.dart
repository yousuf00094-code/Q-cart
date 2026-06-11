import 'package:flutter/material.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/locale_service.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await CustomerService.getAddresses();
      if (mounted) setState(() { _addresses = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(LocaleService.t('delete_address')),
        content: Text(LocaleService.t('delete_address_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(LocaleService.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocaleService.t('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await CustomerService.deleteAddress(id);
      if (mounted) setState(() => _addresses.removeWhere((a) => a['id'] == id));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _setDefault(String id) async {
    try {
      await CustomerService.setDefaultAddress(id);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showAddressForm({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddressFormSheet(
        existing: existing,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, _, __) => Scaffold(
        backgroundColor: const Color(0xFFF8F8FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF2E2E3A)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            LocaleService.t('my_addresses'),
            style: const TextStyle(color: Color(0xFF2E2E3A), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF6C63FF)),
              onPressed: () => _showAddressForm(),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Color(0xFF6B6B7B))),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ))
                : _addresses.isEmpty
                    ? _EmptyState(onAdd: () => _showAddressForm())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _addresses.length,
                          itemBuilder: (_, i) => _AddressCard(
                            address: _addresses[i],
                            onEdit: () => _showAddressForm(existing: _addresses[i]),
                            onDelete: () => _delete(_addresses[i]['id'] as String),
                            onSetDefault: () => _setDefault(_addresses[i]['id'] as String),
                          ),
                        ),
                      ),
        floatingActionButton: _addresses.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _showAddressForm(),
                backgroundColor: const Color(0xFF6C63FF),
                icon: const Icon(Icons.add),
                label: Text(LocaleService.t('add_address')),
              )
            : null,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined, size: 72, color: Color(0xFFD1D1E0)),
            const SizedBox(height: 16),
            Text(
              LocaleService.t('no_addresses'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E2E3A)),
            ),
            const SizedBox(height: 8),
            Text(
              LocaleService.t('add_address_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B6B7B), fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(LocaleService.t('add_address')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Map<String, dynamic> address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final isDefault = address['is_default'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDefault
            ? Border.all(color: const Color(0xFF6C63FF), width: 1.5)
            : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${address['first_name']} ${address['last_name']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E2E3A)),
                  ),
                ),
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      LocaleService.t('default'),
                      style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              address['address_line1'] as String? ?? '',
              style: const TextStyle(color: Color(0xFF6B6B7B), fontSize: 13),
            ),
            if ((address['address_line2'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(address['address_line2'] as String, style: const TextStyle(color: Color(0xFF6B6B7B), fontSize: 13)),
            ],
            const SizedBox(height: 2),
            Text(
              '${address['city']}${address['state'] != null ? ', ${address['state']}' : ''}',
              style: const TextStyle(color: Color(0xFF6B6B7B), fontSize: 13),
            ),
            if ((address['phone'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(address['phone'] as String, style: const TextStyle(color: Color(0xFF6B6B7B), fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isDefault) ...[
                  _ActionButton(
                    label: LocaleService.t('set_default'),
                    icon: Icons.star_outline,
                    color: const Color(0xFF6C63FF),
                    onTap: onSetDefault,
                  ),
                  const SizedBox(width: 8),
                ],
                _ActionButton(
                  label: LocaleService.t('edit'),
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF2E2E3A),
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: LocaleService.t('delete'),
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const _AddressFormSheet({this.existing, required this.onSaved});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _phone;
  bool _isDefault = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _firstName = TextEditingController(text: e?['first_name'] as String? ?? '');
    _lastName  = TextEditingController(text: e?['last_name']  as String? ?? '');
    _line1     = TextEditingController(text: e?['address_line1'] as String? ?? '');
    _line2     = TextEditingController(text: e?['address_line2'] as String? ?? '');
    _city      = TextEditingController(text: e?['city']  as String? ?? '');
    _state     = TextEditingController(text: e?['state'] as String? ?? '');
    _phone     = TextEditingController(text: e?['phone'] as String? ?? '');
    _isDefault = e?['is_default'] as bool? ?? false;
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _line1, _line2, _city, _state, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    final data = {
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'address_line1': _line1.text.trim(),
      if (_line2.text.trim().isNotEmpty) 'address_line2': _line2.text.trim(),
      'city': _city.text.trim(),
      if (_state.text.trim().isNotEmpty) 'state': _state.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      'is_default': _isDefault,
    };
    try {
      if (widget.existing != null) {
        await CustomerService.updateAddress(widget.existing!['id'] as String, data);
      } else {
        await CustomerService.createAddress(data);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE0E0EA), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? LocaleService.t('edit_address') : LocaleService.t('add_address'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E2E3A)),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                ),
              ],
              Row(children: [
                Expanded(child: _Field(ctrl: _firstName, label: LocaleService.t('first_name'), required: true)),
                const SizedBox(width: 12),
                Expanded(child: _Field(ctrl: _lastName, label: LocaleService.t('last_name'), required: true)),
              ]),
              const SizedBox(height: 12),
              _Field(ctrl: _line1, label: LocaleService.t('address_line1'), required: true),
              const SizedBox(height: 12),
              _Field(ctrl: _line2, label: LocaleService.t('address_line2')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _Field(ctrl: _city, label: LocaleService.t('city'), required: true)),
                const SizedBox(width: 12),
                Expanded(child: _Field(ctrl: _state, label: LocaleService.t('state'))),
              ]),
              const SizedBox(height: 12),
              _Field(ctrl: _phone, label: LocaleService.t('phone'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                title: Text(LocaleService.t('set_as_default'), style: const TextStyle(fontSize: 14)),
                activeColor: const Color(0xFF6C63FF),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(LocaleService.t('save'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool required;
  final TextInputType? keyboardType;

  const _Field({required this.ctrl, required this.label, this.required = false, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF4F4F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? '$label required' : null : null,
    );
  }
}
