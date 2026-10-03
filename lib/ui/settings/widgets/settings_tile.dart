import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Uppercase section header used above [SettingsCard]s.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

/// JetBrains-style rounded card holding a list of [SettingsTile]s.
///
/// Tiles inside are separated by hairline dividers that stop short of the left
/// gutter (icon column) — matches IntelliJ / VS Code settings rows.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tiles = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      tiles.add(children[i]);
      if (i != children.length - 1) {
        tiles.add(_IndentDivider(color: colors.border));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        // Floating welcome-screen card style: soft double shadow instead of
        // a hard border.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: tiles,
        ),
      ),
    );
  }
}

/// A single settings row: leading icon, title + subtitle, trailing control.
///
/// Behaviour of the trailing widget is supplied by the caller — pass a
/// [Switch], [DropdownButton], [Text], [IconButton], etc.
class SettingsTile extends StatefulWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final CrossAxisAlignment crossAxisAlignment;
  final bool enabled;

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final titleColor = widget.enabled
        ? colors.textPrimary
        : colors.textDisabled;
    final subtitleColor = widget.enabled
        ? colors.textSecondary
        : colors.textDisabled;
    final leading = widget.leading;
    final effectiveLeading = leading == null
        ? null
        : IconTheme(
            data: IconThemeData(
              color: widget.enabled
                  ? colors.textSecondary
                  : colors.textDisabled,
              size: 18,
            ),
            child: leading,
          );
    return MouseRegion(
      cursor: widget.onTap != null && widget.enabled
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: widget.onTap != null
          ? (_) => setState(() => _hovering = true)
          : null,
      onExit: widget.onTap != null
          ? (_) => setState(() => _hovering = false)
          : null,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          color: _hovering
              ? colors.surfaceLowered.withValues(alpha: 0.5)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: widget.crossAxisAlignment,
            children: [
              if (effectiveLeading != null) ...[
                effectiveLeading,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                Flexible(child: widget.trailing!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline toggle row. Tapping anywhere on the tile flips the switch.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      enabled: enabled,
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
      trailing: Switch(value: value, onChanged: enabled ? onChanged : null),
    );
  }
}

/// Small status pill used for ‘Planned’ / ‘Connected’ / ‘Disconnected’.
class SettingsBadge extends StatelessWidget {
  const SettingsBadge.planned({super.key, required this.label})
    : _kind = _BadgeKind.planned;

  const SettingsBadge.connected({super.key, required this.label})
    : _kind = _BadgeKind.connected;

  const SettingsBadge.disconnected({super.key, required this.label})
    : _kind = _BadgeKind.disconnected;

  const SettingsBadge.neutral({super.key, required this.label})
    : _kind = _BadgeKind.neutral;

  final String label;
  final _BadgeKind _kind;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final (Color bg, Color fg, Color border) = switch (_kind) {
      _BadgeKind.planned => (
        colors.accent.withValues(alpha: 0.14),
        colors.accent,
        colors.accent.withValues(alpha: 0.32),
      ),
      _BadgeKind.connected => (
        colors.success.withValues(alpha: 0.16),
        colors.success,
        colors.success.withValues(alpha: 0.34),
      ),
      _BadgeKind.disconnected => (
        colors.textDisabled.withValues(alpha: 0.18),
        colors.textSecondary,
        colors.border,
      ),
      _BadgeKind.neutral => (
        colors.surfaceLowered,
        colors.textSecondary,
        colors.border,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: fg,
        ),
      ),
    );
  }
}

enum _BadgeKind { planned, connected, disconnected, neutral }

/// Hairline divider that respects the icon-column indent.
class _IndentDivider extends StatelessWidget {
  const _IndentDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Container(height: 1, color: color),
    );
  }
}

/// Compact segmented control bound to a small enum.
///
/// Renders a row of equal-width buttons; the selected one is filled with the
/// accent colour. Used for theme / language / units / provider pickers.
class SettingsSegmentedControl<T> extends StatelessWidget {
  const SettingsSegmentedControl({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final T value;
  final List<SettingsSegment<T>> items;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowered,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            Flexible(
              fit: FlexFit.loose,
              child: _buildSegment(context, item, colors),
            ),
        ],
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context,
    SettingsSegment<T> item,
    AppColors colors,
  ) {
    final selected = item.value == value;
    final bg = selected ? colors.accent : Colors.transparent;
    final fg = selected
        ? (Theme.brightnessOf(context) == Brightness.light
              ? Colors.white
              : Colors.black)
        : (enabled ? colors.textPrimary : colors.textDisabled);
    return InkWell(
      onTap: enabled && onChanged != null ? () => onChanged!(item.value) : null,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          item.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// One segment of a [SettingsSegmentedControl].
class SettingsSegment<T> {
  const SettingsSegment({required this.value, required this.label});

  final T value;
  final String label;
}
