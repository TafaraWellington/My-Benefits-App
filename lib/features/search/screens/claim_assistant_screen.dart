import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/fsca_models.dart';
import '../services/claim_assistant_service.dart';
import '../services/pdf_service.dart';
import 'pdf_preview_screen.dart';
import '../../payment/providers/credit_provider.dart';
import '../../payment/screens/paywall_screen.dart';

class ClaimAssistantScreen extends ConsumerWidget {
  final BenefitResult result;
  final EnquirerDetails enquirer;
  final TargetDetails target;

  const ClaimAssistantScreen({
    super.key,
    required this.result,
    required this.enquirer,
    required this.target,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(creditProvider).isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim Assistant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isPremium 
                        ? 'We have prepared an inquiry email for you. You can review and send it below.'
                        : 'Unlock the Claim Assistant to generate formal letters and email drafts for administrators.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('EMAIL PREVIEW', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreviewField('To', 'Administrator (${result.administrator})'),
                  const Divider(),
                  _buildPreviewField('Subject', 'Unclaimed Benefit Inquiry: ${result.fundName}'),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    isPremium
                      ? 'Dear ${result.administrator},\n\n'
                        'I am writing to inquire about an unclaimed benefit match found via the SA Benefits utility app...\n\n'
                        '[Full details included in draft]'
                      : 'Dear [Administrator],\n\n'
                        'I am writing to inquire about... [Content Hidden]\n\n'
                        'Upgrade to Premium to unlock full draft.',
                    style: TextStyle(height: 1.5, color: isPremium ? Colors.black87 : Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            if (isPremium) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('SEND EMAIL DRAFT'),
                  onPressed: () => _handleSend(context),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'This will open your default email app',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('GENERATE FORMAL PDF LETTER'),
                  onPressed: () => _handlePdf(context),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.star, color: Colors.white),
                  label: const Text('UNLOCK PREMIUM ASSISTANT'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const PaywallScreen(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Starter Pack required for full assistant features',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handlePdf(BuildContext context) async {
    final pdfData = await PdfService.generateClaimLetter(
      enquirer: enquirer,
      target: target,
      benefit: result,
    );

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(pdfData: pdfData),
        ),
      );
    }
  }

  Widget _buildPreviewField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _handleSend(BuildContext context) async {
    try {
      await ClaimAssistantService.initiateClaimEmail(
        result: result,
        enquirer: enquirer,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
