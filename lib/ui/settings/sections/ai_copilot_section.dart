import 'package:flutter/material.dart';

import '../../../data/ai/gateway_process.dart';
import '../../../data/ai/letta_cli_service.dart';
import '../../../data/background_tasks.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/floating_window.dart';
import '../settings_page.dart';
import '../widgets/settings_tile.dart';

/// AI Copilot settings — the Letta CLI runtime.
///
/// The whole section is a state machine around the Letta CLI:
/// environment check → Node.js missing / too old → one-click install →
/// installed (with one-click uninstall). Model providers are connected
/// through Letta's own `/connect` CLI flow.
class AiCopilotSection extends StatefulWidget {
  const AiCopilotSection({super.key});

  @override
  State<AiCopilotSection> createState() => _AiCopilotSectionState();
}

class _AiCopilotSectionState extends State<AiCopilotSection> {
  LettaCliStatus? _status;
  bool _checking = true;
  bool _busy = false;
  bool _busyIsUninstall = false;
  final List<String> _log = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _recheck();
  }

  Future<void> _recheck() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    final status = await LettaCliService.instance.checkStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
      _checking = false;
    });
  }

  Future<void> _install() => _runOperation(uninstall: false);

  Future<void> _uninstall() => _runOperation(uninstall: true);

  Future<void> _runOperation({required bool uninstall}) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _busyIsUninstall = uninstall;
      _log.clear();
      _error = null;
    });
    final task = BackgroundTaskManager.instance.startTask(
      uninstall ? l10n.aiLettaUninstalling : l10n.aiLettaInstalling,
    );
    try {
      var lines = 0;
      final Future<void> op = uninstall
          ? LettaCliService.instance.uninstall(
          onOutput: (line) => _onLine(task, lines++, line))
          : LettaCliService.instance.install(
          onOutput: (line) => _onLine(task, lines++, line));
      await op;
      BackgroundTaskManager.instance.completeTask(task);
    } on LettaCliException catch (e) {
      BackgroundTaskManager.instance.failTask(task, e.message);
      if (!mounted) return;
      setState(() {
        _error = e.tailText.isEmpty
            ? (uninstall ? l10n.aiLettaUninstallFailed : l10n
            .aiLettaInstallFailed)
            : e.tailText;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
      await _recheck();
    }
  }

  void _onLine(ScanTask task, int lineNo, String line) {
    if (!mounted) return;
    BackgroundTaskManager.instance.updateTask(
      task,
      (lineNo / 60).clamp(0.0, 0.95),
    );
    setState(() {
      _log.add(line);
      if (_log.length > 40) _log.removeAt(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsSectionBody(
      title: l10n.settingsAiTitle,
      description: l10n.settingsAiDesc,
      children: [
        SettingsSectionTitle(l10n.aiLettaRuntimeTitle),
        _buildStateCard(context),
        const SizedBox(height: 12),
        _buildDangerCard(context),
        if (_busy && _log.isNotEmpty) ...[
          const SizedBox(height: 12),
          _LogBox(lines: _log, header: l10n.aiLettaLog),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorRow(message: _error!),
        ],
      ],
    );
  }

  // ── One-click Letta data wipe ─────────────────────────────────────────────

  void _confirmDeleteLettaData(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    late OverlayEntry confirmEntry;
    confirmEntry = OverlayEntry(
      builder: (ctx) =>
          FloatingWindow(
            title: l10n.aiDeleteLettaData,
            titleIcon: Icons.warning_amber_rounded,
            width: 400,
            height: 210,
            onClose: () => confirmEntry.remove(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 32,
                    color: Theme.of(ctx).extension<AppColors>()!.danger,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.aiDeleteLettaDataDesc,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(ctx).extension<AppColors>()!
                          .textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => confirmEntry.remove(),
                        child: Text(l10n.settingsCancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                          Theme.of(ctx).extension<AppColors>()!.danger,
                        ),
                        onPressed: () {
                          confirmEntry.remove();
                          _deleteLettaData();
                        },
                        child: Text(l10n.aiDeleteLettaData),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    Overlay.of(context).insert(confirmEntry);
  }

  Future<void> _deleteLettaData() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _busyIsUninstall = false;
      _log.clear();
      _error = null;
    });
    final ok = await GatewayProcess.deleteLettaData();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = ok ? null : l10n.aiDeleteLettaDataFailed;
    });
  }

  Widget _buildDangerCard(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return SettingsCard(
      children: [
        SettingsTile(
          title: l10n.aiDeleteLettaData,
          subtitle: l10n.aiDeleteLettaDataHint,
          leading: Icon(Icons.delete_forever_rounded,
              size: 22, color: colors.danger),
          trailing: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _confirmDeleteLettaData(context),
            icon: const Icon(Icons.delete_rounded, size: 15),
            label: Text(l10n.aiDeleteLettaData),
          ),
        ),
      ],
    );
  }

  Widget _buildStateCard(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final status = _status;

    if (_checking && status == null) {
      return SettingsCard(
        children: [
          SettingsTile(
            title: l10n.aiLettaChecking,
            leading: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      );
    }

    if (_busy) {
      return SettingsCard(
        children: [
          SettingsTile(
            title: _busyIsUninstall
                ? l10n.aiLettaUninstalling
                : l10n.aiLettaInstalling,
            leading: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      );
    }

    if (status == null || !status.nodeInstalled) {
      return _NodeMissingCard(
        title: l10n.aiLettaNodeMissingTitle,
        onDownload: () => LettaCliService.instance.openNodeDownloadPage(),
        onRecheck: _recheck,
      );
    }
    if (!status.nodeMeetsMinimum) {
      return _NodeMissingCard(
        title: l10n.aiLettaNodeTooOldTitle,
        subtitle: status.nodeVersion == null
            ? null
            : l10n.aiLettaNodeDetected(status.nodeVersion!),
        onDownload: () => LettaCliService.instance.openNodeDownloadPage(),
        onRecheck: _recheck,
      );
    }

    if (!status.lettaInstalled) {
      return SettingsCard(
        children: [
          SettingsTile(
            title: l10n.aiLettaNotInstalledTitle,
            subtitle: l10n.aiLettaIntro,
            leading: Icon(Icons.smart_toy_outlined,
                size: 22, color: colors.textSecondary),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: l10n.aiLettaRecheck,
                onPressed: _recheck,
                icon: Icon(Icons.refresh_rounded,
                    size: 18, color: colors.textSecondary),
                constraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                onPressed: _install,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: Text(l10n.aiLettaInstall),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 13, color: colors.textDisabled),
                const SizedBox(width: 6),
                Text(
                  l10n.aiLettaNodeRequiredHint,
                  style:
                  TextStyle(fontSize: 10.5, color: colors.textDisabled),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return SettingsCard(
      children: [
        SettingsTile(
          title: l10n.aiLettaInstalledTitle,
          subtitle: l10n.aiLettaIntro,
          leading:
          Icon(Icons.smart_toy_rounded, size: 22, color: colors.success),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            SettingsBadge.connected(
                label: 'v${status.lettaVersion ?? '?'}'),
            const SizedBox(width: 10),
            IconButton(
              tooltip: l10n.aiLettaRecheck,
              onPressed: _recheck,
              icon: Icon(Icons.refresh_rounded,
                  size: 18, color: colors.textSecondary),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 4),
            OutlinedButton.icon(
              onPressed: () => _confirmUninstall(context),
              icon: const Icon(Icons.delete_outline_rounded, size: 15),
              label: Text(l10n.aiLettaUninstall),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 13, color: colors.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.aiLettaReadyHint,
                  style: TextStyle(fontSize: 10.5, color: colors.textDisabled),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmUninstall(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) =>
          FloatingWindow(
            title: l10n.aiLettaUninstallConfirmTitle,
            titleIcon: Icons.warning_amber_rounded,
            width: 420,
            height: 210,
            onClose: () => entry.remove(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 32, color: colors.danger),
                  const SizedBox(height: 12),
                  Text(
                    l10n.aiLettaUninstallConfirmDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.5, color: colors.textSecondary),
                  ),
                  const Spacer(),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                      onPressed: () => entry.remove(),
                      child: Text(l10n.settingsCancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style:
                      FilledButton.styleFrom(backgroundColor: colors.danger),
                      onPressed: () {
                        entry.remove();
                        _uninstall();
                      },
                      child: Text(l10n.aiLettaUninstall),
                    ),
                  ]),
                ],
              ),
            ),
          ),
    );
    Overlay.of(context).insert(entry);
  }
}

class _NodeMissingCard extends StatelessWidget {
  const _NodeMissingCard({
    required this.title,
    required this.onDownload,
    required this.onRecheck,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onDownload;
  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return SettingsCard(
      children: [
        SettingsTile(
          title: title,
          subtitle: subtitle ?? l10n.aiLettaNodeRequiredHint,
          leading:
          Icon(Icons.warning_amber_rounded, size: 22, color: colors.warning),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              tooltip: l10n.aiLettaRecheck,
              onPressed: onRecheck,
              icon:
              Icon(
                  Icons.refresh_rounded, size: 18, color: colors.textSecondary),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: Text(l10n.aiLettaNodeDownload),
            ),
          ]),
        ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.danger.withValues(alpha: 0.4)),
      ),
      child: SelectableText(
        message,
        style: TextStyle(
          fontSize: 10.5,
          fontFamily: 'monospace',
          color: colors.danger,
        ),
      ),
    );
  }
}

class _LogBox extends StatelessWidget {
  const _LogBox({required this.lines, required this.header});

  final List<String> lines;
  final String header;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceLowered,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            header.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: colors.textDisabled,
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: SingleChildScrollView(
              reverse: true,
              child: SelectableText(
                lines.join('\n'),
                style: TextStyle(
                  fontSize: 10,
                  height: 1.4,
                  fontFamily: 'monospace',
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
