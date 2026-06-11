import 'package:flutter/material.dart';
import '../../../core/services/locale_service.dart';

class PaymentFailedScreen extends StatelessWidget {
  final String? errorMessage;
  const PaymentFailedScreen({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cancel_outlined, size: 72, color: Colors.red.shade600),
              ),
              const SizedBox(height: 28),
              Text(
                LocaleService.t('payment_failed'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2E2E3A)),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage ?? LocaleService.t('payment_failed_msg'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF6B6B7B)),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop back to checkout so the user can retry
                    Navigator.popUntil(context, (r) => r.settings.name == '/checkout' || r.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(LocaleService.t('try_again'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B6B7B),
                    side: const BorderSide(color: Color(0xFFD1D1E0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(LocaleService.t('continue_shopping'), style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
