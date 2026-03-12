import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({super.key});

  static const String privacyPolicyUrl = 'https://avahanaa.com/privacy-policy.html';
  static const String termsOfServiceUrl = 'https://avahanaa.com/terms-and-conditions.html';

  Future<void> _openExternalUrl(BuildContext context, String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the link right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal & Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Privacy Policy'),
              subtitle: const Text(
                'How Avahanaa collects, uses, and protects user data.',
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openExternalUrl(context, privacyPolicyUrl),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Terms of Service'),
              subtitle: const Text(
                'Rules, responsibilities, and terms for using Avahanaa.',
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openExternalUrl(context, termsOfServiceUrl),
            ),
          ),
        ],
      ),
    );
  }
}
