import 'package:url_launcher/url_launcher.dart';
import '../models/fsca_models.dart';

class ClaimAssistantService {
  static Future<void> initiateClaimEmail({
    required BenefitResult result,
    required EnquirerDetails enquirer,
  }) async {
    final String subject = Uri.encodeComponent('Unclaimed Benefit Inquiry: ${result.fundName}');
    final String body = Uri.encodeComponent(
      'Dear ${result.administrator},\n\n'
      'I am writing to inquire about an unclaimed benefit match found via the SA Benefits utility app.\n\n'
      'Target Details:\n'
      '- Fund Name: ${result.fundName}\n'
      '- Potential Match Status: ${result.status}\n\n'
      'Enquirer Details:\n'
      '- Name: ${enquirer.names} ${enquirer.surname}\n'
      '- Contact: ${enquirer.cellNumber}\n'
      '- Email: ${enquirer.email}\n\n'
      'Please let me know the next steps for formal verification and claim submission.\n\n'
      'Kind regards,\n'
      '${enquirer.names} ${enquirer.surname}'
    );

    // Note: In a real scenario, we would parse result.contactDetails to find an email.
    // For this demo, we'll use a placeholder or the first email found in contactDetails.
    String recipient = 'info@fsca.co.za'; // Default placeholder
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    final match = emailRegex.firstMatch(result.contactDetails);
    if (match != null) {
      recipient = match.group(0)!;
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: recipient,
      query: 'subject=$subject&body=$body',
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch email app';
    }
  }
}
