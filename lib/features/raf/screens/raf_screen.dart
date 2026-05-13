import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import 'raf_form_screen.dart';

class RafScreen extends StatelessWidget {
  const RafScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RAF Inquiry Guide')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.car_crash_outlined, size: 80, color: AppColors.accent),
          const SizedBox(height: 24),
          Text(
            'Track Your RAF Claim',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'The Road Accident Fund (RAF) does not currently provide a real-time online dashboard for public status checks. Use the official channels below to inquire about your claim.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildActionCard(
            context,
            title: 'Call RAF Centre',
            subtitle: '0860 23 55 23',
            icon: Icons.phone_forwarded,
            onTap: () => _launchCaller('0860235523'),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            title: 'Email RAF',
            subtitle: 'customerservice@raf.co.za',
            icon: Icons.email_outlined,
            onTap: () => _launchEmail('customerservice@raf.co.za'),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            title: 'Generate Inquiry Letter',
            subtitle: 'Create a formal PDF letter',
            icon: Icons.picture_as_pdf,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RafFormScreen()),
            ),
          ),
          const SizedBox(height: 32),
          Text('Inquiry Checklist', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildChecklistItem('RAF Claim Reference Number'),
          _buildChecklistItem('Your 13-digit ID Number'),
          _buildChecklistItem('Date of the Accident'),
          _buildChecklistItem('Full Name of the Claimant'),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Always verify you are speaking to an official RAF representative. Never share your bank PIN.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.open_in_new, size: 16),
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_box_outline_blank, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _launchCaller(String number) async {
    final url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _launchEmail(String email) async {
    final url = Uri.parse('mailto:$email?subject=Claim Inquiry');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}
