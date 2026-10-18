import 'dart:io' show Platform, Process;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/floating_dialog.dart';
import '../settings_page.dart';
import '../widgets/settings_tile.dart';

/// Version, license and credits. Read-only — no settings are mutated here.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key, required this.controller});

  final SettingsController controller;

  // The homepage URL is a project constant — declared here rather than as a
  // setting so it stays in sync with pubspec.yaml.
  static const String homepageUrl =
      'https://github.com/Sycreaper/flight-studio';

  /// Opens the project homepage in the system browser (best-effort).
  Future<void> _openHomepage() async {
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', homepageUrl],
          runInShell: true);
    } else if (Platform.isMacOS) {
      await Process.run('open', [homepageUrl]);
    } else {
      await Process.run('xdg-open', [homepageUrl]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    return SettingsSectionBody(
      title: l10n.settingsAboutTitle,
      description: l10n.settingsCategoryAboutDesc,
      children: [
        // Flight Studio branded hero — the app logo (same SVG as the
        // welcome drawer, the launcher icons and the About page).
        Center(
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SvgPicture.asset('assets/icons/logo.svg'),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.appName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.settingsAboutInspiredBy,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SettingsSectionTitle(l10n.settingsAboutVersion),
        SettingsCard(
          children: [
            SettingsTile(
              title: l10n.settingsAboutVersion,
              leading: const Icon(Icons.tag_rounded),
              trailing: const Text('0.1.0+1'),
            ),
            SettingsTile(
              title: l10n.settingsAboutLicense,
              subtitle: l10n.settingsAboutLicenseValue,
              leading: const Icon(Icons.balance_rounded),
              trailing: OutlinedButton(
                onPressed: () => _showLicenseDialog(context, l10n),
                child: Text(l10n.settingsAboutViewLicense),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SettingsSectionTitle(l10n.settingsAboutThirdParty),
        SettingsCard(
          children: [
            SettingsTile(
              title: l10n.settingsAboutThirdParty,
              subtitle: l10n.settingsAboutThirdPartyDesc,
              leading: const Icon(Icons.copyright_rounded),
              crossAxisAlignment: CrossAxisAlignment.start,
              trailing: OutlinedButton(
                onPressed: () => _showThirdPartyDialog(context, l10n),
                child: Text(l10n.settingsAboutViewThirdParty),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SettingsSectionTitle(l10n.settingsAboutHomepage),
        SettingsCard(
          children: [
            SettingsTile(
              title: l10n.settingsAboutHomepage,
              subtitle: homepageUrl,
              leading: const Icon(Icons.public_rounded),
              trailing: OutlinedButton(
                onPressed: _openHomepage,
                child: Text(l10n.settingsAboutOpenSource),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLicenseDialog(BuildContext context, AppLocalizations l10n) {
    showFloatingDialog(
      context,
      title: l10n.settingsAboutLicense,
      width: 560,
      height: 480,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Text(
            _mitLicenseText,
            style: const TextStyle(fontSize: 12, height: 1.5),
          ),
        ),
      ),
    );
  }

  void _showThirdPartyDialog(BuildContext context, AppLocalizations l10n) {
    showFloatingDialog(
      context,
      title: l10n.settingsAboutThirdParty,
      width: 560,
      height: 400,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Text(
            l10n.settingsAboutThirdPartyDesc,
            style: const TextStyle(fontSize: 12, height: 1.6),
          ),
        ),
      ),
    );
  }
}

const String _mitLicenseText = '''MIT License

Copyright (c) 2026 Flight Studio contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.''';
