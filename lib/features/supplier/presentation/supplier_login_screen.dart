import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/supplier_service.dart';

class SupplierLoginScreen extends StatefulWidget {
  const SupplierLoginScreen({super.key});

  @override
  State<SupplierLoginScreen> createState() => _SupplierLoginScreenState();
}

class _SupplierLoginScreenState extends State<SupplierLoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool   _obscurePassword = true;
  bool   _loading         = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMessage = null; });

    try {
      final user = await AuthService.login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );

      // Only suppliers (and admins) may use this portal.
      final role = user['role']?.toString() ?? '';
      if (role != 'supplier' && role != 'admin') {
        await AuthService.logout();
        setState(() => _errorMessage = 'This portal is for suppliers only.');
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/supplier');
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'EMAIL_NOT_VERIFIED' => 'Please verify your email before signing in.',
          'INVALID_CREDENTIALS' => 'Incorrect email or password.',
          'ACCOUNT_INACTIVE' => 'Your account has been deactivated. Contact support.',
          _ => e.message,
        };
      });
    } catch (_) {
      setState(() => _errorMessage = 'Connection failed. Please check your network.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildForm(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorBanner(_errorMessage!),
              ],
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 24),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.store_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 20),
        const Text(
          'Supplier Portal',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sign in to manage your products and orders',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Business Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) =>
                v == null || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) =>
                v == null || v.length < 6 ? 'Password too short' : null,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordSheet(),
              child: const Text(
                'Forgot password?',
                style: TextStyle(color: AppColors.secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Color(0xFFC62828), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Not a supplier yet?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: () => _showApplySheet(),
            child: const Text(
              'Apply to sell on Q Cart',
              style: TextStyle(
                  color: AppColors.secondary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 4),
              Text('Secured by TLS 1.3',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordSheet() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    bool sending = false;
    String? sent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reset Password',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                  'Enter your business email and we\'ll send a reset link.',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Business Email',
                    prefixIcon: Icon(Icons.email_outlined)),
              ),
              if (sent != null) ...[
                const SizedBox(height: 12),
                Text(sent!,
                    style: const TextStyle(
                        color: Color(0xFF2E7D32), fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: sending
                      ? null
                      : () async {
                          setSheetState(() => sending = true);
                          try {
                            await ApiClient.post('/auth/forgot-password',
                                {'email': emailCtrl.text.trim()});
                            setSheetState(() {
                              sent = 'Reset link sent. Check your inbox.';
                              sending = false;
                            });
                          } catch (_) {
                            setSheetState(() {
                              sent = 'If that email exists, a reset link was sent.';
                              sending = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Send Reset Link',
                          style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApplySheet() {
    final formKey  = GlobalKey<FormState>();
    final bizCtrl  = TextEditingController();
    final crCtrl   = TextEditingController();
    final emailCtrl= TextEditingController();
    final phoneCtrl= TextEditingController();
    final catCtrl  = TextEditingController();
    bool submitting = false;
    String? errorMsg;
    bool success = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          builder: (_, scrollCtrl) => SingleChildScrollView(
            controller: scrollCtrl,
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: success
                ? _buildApplySuccess(() => Navigator.pop(context))
                : Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Become a Supplier',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        const Text(
                            'Join the Q Cart supplier network and reach thousands of customers in Qatar.',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: bizCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Business Name *',
                              prefixIcon: Icon(Icons.business_outlined)),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: crCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Commercial Registration No.',
                              prefixIcon: Icon(Icons.badge_outlined)),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'Business Email *',
                              prefixIcon: Icon(Icons.email_outlined)),
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined)),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: catCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Primary Product Category',
                              prefixIcon: Icon(Icons.category_outlined)),
                        ),
                        if (errorMsg != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDECEC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE57373)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFC62828), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(errorMsg!,
                                      style: const TextStyle(
                                          color: Color(0xFFC62828),
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: submitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setSheet(() {
                                      submitting = true;
                                      errorMsg = null;
                                    });
                                    try {
                                      await ApiClient.post('/suppliers/apply', {
                                        'business_name': bizCtrl.text.trim(),
                                        'email': emailCtrl.text.trim(),
                                        if (phoneCtrl.text.trim().isNotEmpty)
                                          'phone': phoneCtrl.text.trim(),
                                        if (crCtrl.text.trim().isNotEmpty)
                                          'cr_number': crCtrl.text.trim(),
                                        if (catCtrl.text.trim().isNotEmpty)
                                          'category': catCtrl.text.trim(),
                                      });
                                      setSheet(() { submitting = false; success = true; });
                                    } on ApiException catch (e) {
                                      setSheet(() {
                                        submitting = false;
                                        errorMsg = e.code == 'EMAIL_EXISTS'
                                            ? 'An application with this email already exists.'
                                            : e.message;
                                      });
                                    } catch (_) {
                                      setSheet(() {
                                        submitting = false;
                                        errorMsg = 'Connection failed. Please try again.';
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Submit Application',
                                    style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplySuccess(VoidCallback onDone) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_outline,
              color: Color(0xFF2E7D32), size: 40),
        ),
        const SizedBox(height: 20),
        const Text('Application Submitted!',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text(
            'Our team will review your application within 2 business days and contact you by email.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
