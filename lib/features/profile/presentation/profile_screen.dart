import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/api_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _profile;
  bool _notificationsEnabled = true;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _editFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (AuthService.isLoggedIn) {
      _loadProfile();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await CustomerService.getUserProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showEditProfileSheet() {
    if (_profile == null) return;
    _nameCtrl.text = _profile!['full_name']?.toString() ?? '';
    _phoneCtrl.text = _profile!['phone']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        formKey: _editFormKey,
        nameCtrl: _nameCtrl,
        phoneCtrl: _phoneCtrl,
        onSaved: (updatedProfile) {
          setState(() => _profile = updatedProfile);
        },
      ),
    );
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleService.t('language'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            _languageOption(ctx, 'en', LocaleService.t('english')),
            const SizedBox(height: 8),
            _languageOption(ctx, 'ar', LocaleService.t('arabic')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(BuildContext ctx, String code, String label) {
    final isSelected = LocaleService.code == code;
    return ListTile(
      onTap: () {
        LocaleService.setLocale(code);
        Navigator.pop(ctx);
        setState(() {});
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.secondary : AppColors.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      tileColor: isSelected ? AppColors.secondary.withOpacity(0.05) : AppColors.surface,
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.secondary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.secondary) : null,
    );
  }

  String _memberSince() {
    final createdAt = _profile?['created_at']?.toString() ?? '';
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _avatarLetter() {
    final name = _profile?['full_name']?.toString() ?? AuthService.currentUser?['full_name']?.toString() ?? '';
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }

    if (!AuthService.isLoggedIn) {
      return _buildGuestView();
    }

    return _buildLoggedInView();
  }

  Widget _buildGuestView() {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  'Q Cart',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleService.t('sign_in_to_continue'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(LocaleService.t('login'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(LocaleService.t('no_account'), style: const TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: Text(
                        LocaleService.t('register'),
                        style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInView() {
    final fullName = _profile?['full_name']?.toString() ?? '';
    final email = _profile?['email']?.toString() ?? '';
    final loyaltyPoints = (_profile?['loyalty_points'] as num?)?.toInt() ?? 0;
    final since = _memberSince();
    final currentLang = LocaleService.isArabic ? LocaleService.t('arabic') : LocaleService.t('english');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: AppColors.background,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _avatarLetter(),
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          if (since.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${LocaleService.t('member_since')} $since',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showEditProfileSheet,
                      icon: const Icon(Icons.edit_outlined, color: AppColors.secondary, size: 20),
                    ),
                  ],
                ),
              ),
              Container(
                color: AppColors.background,
                margin: const EdgeInsets.only(top: 1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _statItem(
                        icon: Icons.stars_outlined,
                        value: '$loyaltyPoints',
                        label: LocaleService.t('loyalty_points'),
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppColors.divider),
                    Expanded(
                      child: _statItem(
                        icon: Icons.receipt_long_outlined,
                        value: '',
                        label: LocaleService.t('orders_label'),
                        onTap: () => Navigator.pushNamed(context, '/orders'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionHeader(LocaleService.t('account')),
              _menuItem(
                icon: Icons.person_outline,
                title: LocaleService.t('personal_info'),
                onTap: _showEditProfileSheet,
              ),
              _menuItem(
                icon: Icons.location_on_outlined,
                title: LocaleService.t('my_addresses'),
                onTap: () => Navigator.pushNamed(context, '/profile/addresses'),
              ),
              _menuItem(
                icon: Icons.receipt_long_outlined,
                title: LocaleService.t('my_orders'),
                onTap: () => Navigator.pushNamed(context, '/orders'),
              ),
              const SizedBox(height: 16),
              _sectionHeader(LocaleService.t('settings')),
              _menuItem(
                icon: Icons.language_outlined,
                title: LocaleService.t('language'),
                trailing: Text(currentLang, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                onTap: _showLanguageSheet,
              ),
              Container(
                color: AppColors.background,
                margin: const EdgeInsets.only(bottom: 1),
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                  title: Text(LocaleService.t('notifications'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                    activeColor: AppColors.secondary,
                  ),
                ),
              ),
              _menuItem(
                icon: Icons.help_outline,
                title: LocaleService.t('help_support'),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support coming soon')),
                ),
              ),
              _menuItem(
                icon: Icons.info_outline,
                title: LocaleService.t('about'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Q Cart',
                  applicationVersion: '1.0.0',
                  children: [const Text('Q Cart — Your modern shopping companion.')],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                color: AppColors.background,
                margin: const EdgeInsets.only(bottom: 1),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    LocaleService.t('logout'),
                    style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(LocaleService.t('logout')),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(LocaleService.t('cancel')),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _logout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(LocaleService.t('logout')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondary, size: 22),
          const SizedBox(height: 4),
          if (value.isNotEmpty)
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final void Function(Map<String, dynamic>) onSaved;

  const _EditProfileSheet({
    required this.formKey,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.onSaved,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!widget.formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await CustomerService.updateProfile({
        'full_name': widget.nameCtrl.text.trim(),
        if (widget.phoneCtrl.text.trim().isNotEmpty)
          'phone': widget.phoneCtrl.text.trim(),
      });
      widget.onSaved(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e is ApiException ? e.message : LocaleService.t('error_generic');
      });
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
                LocaleService.t('personal_info'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                ),
                const SizedBox(height: 12),
              ],
              _buildField(widget.nameCtrl, LocaleService.t('full_name'), required: true),
              const SizedBox(height: 12),
              _buildField(widget.phoneCtrl, LocaleService.t('phone'), keyboardType: TextInputType.phone),
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
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(LocaleService.t('save')),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.secondary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }
}
