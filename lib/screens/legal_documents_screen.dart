import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({super.key});

  static const String privacyPolicyUrl =
      'https://avahanaa.com/privacy-policy.html';
  static const String termsOfServiceUrl =
      'https://avahanaa.com/terms-and-conditions.html';

  Future<void> _openExternalUrl(BuildContext context, String rawUrl) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(rawUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      showAppSnackBar(
        messenger,
        'Could not open the link right now.',
        kind: AppSnackKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal & Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          EntranceFade(
            child: AppCard(
              color: AppColors.infoSurface,
              borderColor: AppColors.infoBorder,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIconBadge(
                    icon: Icons.shield_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('The short version', style: AppText.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Avahanaa never reveals your phone number, email or name '
                    'to anyone who scans your QR code — and never reveals the '
                    'scanner’s identity to you. The full documents below spell '
                    'out exactly what is stored and why.',
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          EntranceFade(
            delay: const Duration(milliseconds: 60),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppListRow(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'What we collect, why, and how long we keep it',
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () => _openExternalUrl(context, privacyPolicyUrl),
                  ),
                  const Divider(
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  AppListRow(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    subtitle: 'The rules for using Avahanaa',
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () => _openExternalUrl(context, termsOfServiceUrl),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
