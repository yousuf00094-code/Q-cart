import 'package:flutter/material.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/utils/parse_num.dart';

class PaymentScreen extends StatefulWidget {
  final String addressId;
  final String? couponCode;
  final double total;

  const PaymentScreen({
    super.key,
    required this.addressId,
    this.couponCode,
    required this.total,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _initiating = true;
  bool _verifying = false;
  String? _error;
  String? _invoiceId;
  String? _paymentUrl;
  String? _qrImageBase64;
  double? _amount;

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    setState(() { _initiating = true; _error = null; });
    try {
      final data = await CustomerService.initiatePayment(
        addressId: widget.addressId,
        couponCode: widget.couponCode,
      );
      if (mounted) {
        setState(() {
          _invoiceId = data['invoice_id'] as String?;
          _paymentUrl = data['payment_url'] as String?;
          _qrImageBase64 = data['qr_image'] as String?;
          _amount = parseDoubleOrNull(data['amount']);
          _initiating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : LocaleService.t('error_generic');
          _initiating = false;
        });
      }
    }
  }

  Future<void> _openPaymentUrl() async {
    if (_paymentUrl == null) return;
    // url_launcher is not yet added — show URL for user to copy in this sprint.
    // In production, use launchUrl(Uri.parse(_paymentUrl!)).
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Open in Browser'),
          content: SelectableText(_paymentUrl!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _verifyPayment() async {
    if (_invoiceId == null) return;
    setState(() { _verifying = true; _error = null; });
    try {
      final order = await CustomerService.verifyPayment(_invoiceId!);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/payment/success',
          (r) => r.settings.name == '/',
          arguments: order,
        );
      }
    } catch (e) {
      if (mounted) {
        final isPaymentPending = e is ApiException && e.code == 'PAYMENT_PENDING';
        if (isPaymentPending) {
          setState(() { _verifying = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleService.t('payment_pending')),
              backgroundColor: Colors.orange.shade700,
            ),
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/payment/failed',
            arguments: {'error': e is ApiException ? e.message : LocaleService.t('error_generic')},
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF2E2E3A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          LocaleService.t('payment'),
          style: const TextStyle(color: Color(0xFF2E2E3A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _initiating
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  const SizedBox(height: 16),
                  Text(LocaleService.t('initiating_payment'), style: const TextStyle(color: Color(0xFF6B6B7B))),
                ],
              ),
            )
          : _error != null && _invoiceId == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF2E2E3A))),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _initiatePayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(LocaleService.t('try_again')),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildPaymentContent(),
    );
  }

  Widget _buildPaymentContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_2, size: 80, color: Color(0xFF6C63FF)),
                const SizedBox(height: 12),
                Text(
                  LocaleService.t('scan_qr_code'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E2E3A)),
                ),
                const SizedBox(height: 8),
                if (_amount != null)
                  Text(
                    'QAR ${_amount!.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _InfoStep(number: '1', text: LocaleService.t('open_payment_page')),
          const SizedBox(height: 12),
          _InfoStep(number: '2', text: 'Complete the payment on QPay'),
          const SizedBox(height: 12),
          _InfoStep(number: '3', text: LocaleService.t('payment_completed')),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _openPaymentUrl,
              icon: const Icon(Icons.open_in_browser),
              label: Text(LocaleService.t('open_payment_page')),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
                side: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _verifying ? null : _verifyPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _verifying
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text(LocaleService.t('verifying_payment')),
                      ],
                    )
                  : Text(
                      LocaleService.t('payment_completed'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _InfoStep extends StatelessWidget {
  final String number;
  final String text;
  const _InfoStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
          child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF2E2E3A), fontSize: 14))),
      ],
    );
  }
}
