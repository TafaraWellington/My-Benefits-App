import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/paystack_service.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/credit_provider.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 60, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              'Unlock Search Credits',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Our search assistants manually verify records and coordinate with fund administrators to help you claim what is yours.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 24),
            _buildPricingTier(
              context,
              ref,
              title: 'Gold Premium',
              credits: 1000,
              price: 'R49.00',
              isPopular: true,
              onTap: () => _handlePayment(context, ref, 1000, 49.00),
            ),
            const SizedBox(height: 12),
            _buildPricingTier(
              context,
              ref,
              title: 'Single Search',
              credits: 1,
              price: 'R4.99',
              isPopular: false,
              onTap: () => _handlePayment(context, ref, 1, 4.99),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _launchPaymentLink(),
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Pay via Browser (Alternative)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe later'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPaymentLink() async {
    final url = Uri.parse('https://paystack.shop/pay/yvmhgc6udu');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Widget _buildPricingTier(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required int credits,
    required String price,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isPopular ? AppColors.accent : Colors.grey.shade300,
            width: isPopular ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isPopular ? AppColors.accent.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'BEST VALUE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$credits Search${credits > 1 ? 'es' : ''}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  void _handlePayment(BuildContext context, WidgetRef ref, int credits, double amount) async {
    final paystack = ref.read(paystackServiceProvider);
    
    // Using a dummy email since we don't force login yet
    final success = await paystack.checkout(
      context, 
      amount: amount, 
      email: 'user@example.com'
    );

    if (success) {
      await ref.read(creditProvider.notifier).addCredits(credits);
      // If buying 50 credits, also grant Premium status
      if (credits >= 50) {
        await ref.read(creditProvider.notifier).setPremium(true);
      }
      
      if (context.mounted) {
        Navigator.pop(context); // Close paywall
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully added $credits credits!${credits >= 50 ? " (Premium Unlocked)" : ""}')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled or failed.')),
        );
      }
    }
  }
}
