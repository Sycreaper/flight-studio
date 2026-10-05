import 'package:flutter/material.dart';

import '../../../data/settings/settings_controller.dart';
import '../../../features/flights/flight_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/chat_session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/model_reasoning_chips.dart';
import '../../widgets/prompt_box.dart';
import '../widgets/flight_card.dart';

/// The **Start** page: hero title with a centred floating AI prompt box
/// (white pill → rounded rectangle as you type), model + reasoning-effort
/// chips below it, three compact action buttons, and recent-flight
/// search + list underneath when records exist.
class RecentFlightsPage extends StatefulWidget {
  const RecentFlightsPage({
    super.key,
    required this.repository,
    this.onCreateFlight,
    this.onWorldMap,
    this.onFlightAcademy,
    this.onOpenChat,
    this.settings,
  });

  final FlightRepository repository;
  final VoidCallback? onCreateFlight;
  final VoidCallback? onWorldMap;
  final VoidCallback? onFlightAcademy;

  /// After a prompt send: the shell jumps to the chat tab.
  final VoidCallback? onOpenChat;

  /// Settings (API key vault) driving the model chips.
  final SettingsController? settings;

  @override
  State<RecentFlightsPage> createState() => _RecentFlightsPageState();
}

class _RecentFlightsPageState extends State<RecentFlightsPage> {
  final _search = TextEditingController();
  final _prompt = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final v = _search.text;
      if (v != _query) setState(() => _query = v);
    });
    _prompt.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final all = widget.repository.all();
    final isEmpty = all.isEmpty;
    final results = _query.isEmpty ? all : widget.repository.search(_query);

    return LayoutBuilder(
      builder: (context, viewport) =>
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isEmpty) const Spacer(),
                      Text(
                        l10n.startHeroTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .extension<AppColors>()!
                              .textPrimary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Prompt box + chips share one width constraint, so
                      // the chips align with the box's LEFT edge (not the
                      // page's).
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PromptBox(
                                controller: _prompt,
                                isStreaming: false,
                                onSend: (text) {
                                  ChatSession.instance.send(text);
                                  widget.onOpenChat?.call();
                                },
                                onStop: () => ChatSession.instance.stop(),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: ModelReasoningChips(
                                  settings: widget.settings,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: Wrap(
                          spacing: 12,
                          children: [
                            _StartButton(
                              icon: Icons.edit_note_rounded,
                              label: l10n.createFlight,
                              onTap: widget.onCreateFlight,
                            ),
                            _StartButton(
                              icon: Icons.public_rounded,
                              label: l10n.worldMap,
                              onTap: widget.onWorldMap,
                            ),
                            _StartButton(
                              icon: Icons.school_rounded,
                              label: l10n.flightAcademy,
                              onTap: widget.onFlightAcademy,
                            ),
                          ],
                        ),
                      ),
                      if (!isEmpty) ...[
                        const SizedBox(height: 48),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: _SearchField(controller: _search),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (results.isEmpty)
                                  _Hint(text: l10n.noResults)
                                else
                                  for (var i = 0; i < results.length; i++) ...[
                                    if (i > 0) const SizedBox(height: 8),
                                    FlightCard(
                                        flight: results[i], onTap: () {}),
                                  ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (isEmpty) const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

/// Compact inline action button (icon + label on one line).
class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: colors.accent),
      label: Text(
        label,
        style: TextStyle(fontSize: 12.5, color: colors.textPrimary),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: colors.surfaceRaised,
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: l10n.searchFlights,
        prefixIcon: Icon(Icons.search_rounded,
            size: 18, color: colors.textSecondary),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              onPressed: controller.clear,
              icon: Icon(Icons.close_rounded,
                  size: 16, color: colors.textSecondary),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            );
          },
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Text(text,
          style: TextStyle(fontSize: 13, color: colors.textDisabled)),
    );
  }
}
