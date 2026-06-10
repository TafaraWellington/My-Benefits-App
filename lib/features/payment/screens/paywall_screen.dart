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
              title: 'Platinum Membership',
              subtitle: '250MB Cloud Vault + 5000 Credits',
              price: 'R499.00',
              isPopular: true,
              onTap: () => _handlePayment(
                context, 
                ref, 
                credits: 5000, 
                amount: 499.00, 
                tier: MembershipTier.platinum,
                plan: 'PLN_ims5zxtr3bxos86',
              ),
            ),
            const SizedBox(height: 12),
            _buildPricingTier(
              context,
              ref,
              title: 'Gold Membership',
              subtitle: '100MB Cloud Vault + 1000 Credits',
              price: 'R49.00',
              isPopular: false,
              onTap: () => _handlePayment(
                context, 
                ref, 
                credits: 1000, 
                amount: 49.00, 
                tier: MembershipTier.gold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPricingTier(
              context,
              ref,
              title: 'Single Search',
              subtitle: '1 Credit',
              price: 'R4.99',
              isPopular: false,
              onTap: () => _handlePayment(
                context, 
                ref, 
                credits: 1, 
                amount: 4.99, 
                tier: null,
              ),
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
    required String subtitle,
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
            Expanded(
              child: Column(
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
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),

          ],
        ),
      ),
    );
  }

  void _handlePayment(
    BuildContext context, 
    WidgetRef ref, {
    required int credits, 
    required double amount, 
    MembershipTier? tier,
    String? plan,
  }) async {
    final paystack = ref.read(paystackServiceProvider);
    final supabase = ref.read(supabaseServiceProvider);
    final currentUser = supabase.currentUser;

    // 1. Ensure user is logged in
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to buy credits and sync them securely with your account.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    
    // 2. Show loading progress indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: AppColors.cardBg,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.accent),
                SizedBox(height: 16),
                Text(
                  'Preparing Secure Checkout...',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final reference = 'TRANS_${DateTime.now().millisecondsSinceEpoch}';

    // 3. Initialize payment with Server REST API
    final urlStr = await paystack.initializeTransaction(
      amount: amount,
      email: currentUser.email ?? 'user@example.com',
      reference: reference,
      userId: currentUser.id,
      credits: credits,
      tier: tier?.name,
    );

    // Close loading indicator
    if (context.mounted) Navigator.pop(context);

    if (urlStr == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to initialize payment. Please check your connection and try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // 4. Launch URL in native external browser
    final checkoutUri = Uri.parse(urlStr);
    if (!await launchUrl(checkoutUri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open checkout page. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // 5. Show Verification Dialog
    if (context.mounted) {
      _showVerificationDialog(context, ref, reference, credits, tier);
    }
  }

  void _showVerificationDialog(
    BuildContext context,
    WidgetRef ref,
    String reference,
    int credits,
    MembershipTier? tier,
  ) {
    bool verifying = false;
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.payment_outlined, size: 60, color: AppColors.accent),
                    const SizedBox(height: 16),
                    const Text(
                      'Confirm Payment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please complete your payment in the browser window that opened. Once done, tap below to sync and activate your account!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMsg!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: verifying
                            ? null
                            : () async {
                                setDialogState(() {
                                  verifying = true;
                                  errorMsg = null;
                                });

                                // Capture state before sync
                                final oldState = ref.read(creditProvider);

                                // Sync profile details from Supabase (updated via Webhook)
                                await ref.read(creditProvider.notifier).syncWithServer();

                                final newState = ref.read(creditProvider);
                                final hasUpdated = newState.credits > oldState.credits || 
                                                 (tier != null && newState.tier == tier);

                                if (hasUpdated) {
                                  if (context.mounted) {
                                    Navigator.pop(context); // Close Verification Dialog
                                    Navigator.pop(context); // Close Paywall
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Payment successful! Added $credits credits!${tier != null ? " (${tier.name.toUpperCase()} Unlocked)" : ""}',
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } else {
                                  setDialogState(() {
                                    verifying = false;
                                    errorMsg = 'Payment check failed. Please ensure you finished the payment inside the web page and try again.';
                                  });
                                }
                              },
                        child: verifying
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('VERIFY PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: verifying
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: const Text('Cancel / Pay Later', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

