import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A vertically or horizontally collapsible panel, inspired by JetBrains IDEA
/// tool windows. Renders a titled, rounded container that can be toggled open or
/// collapsed to a header strip.
class CollapsiblePanel extends StatelessWidget {
  const CollapsiblePanel({
    super.key,
    required this.title,
    required this.child,
    required this.isExpanded,
    required this.onToggle,
    this.width,
    this.headerHeight = 34,
    this.actions = const [],
    this.scrollable = true,
    this.padding,
    this.bordered = true,
    this.divider = true,
  });

  final String title;
  final Widget child;
  final bool isExpanded;
  final VoidCallback onToggle;
  final double? width;
  final double headerHeight;
  final List<Widget> actions;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final bool bordered;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final content = isExpanded
        ? Expanded(
            child: scrollable
                ? SingleChildScrollView(
                    padding: padding ??
                        const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: child,
                  )
                : Padding(
                    padding: padding ??
                        const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: child,
                  ),
          )
        : const SizedBox.shrink();

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: bordered ? Border.all(color: colors.border) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            title: title,
            isExpanded: isExpanded,
            onToggle: onToggle,
            actions: actions,
            height: headerHeight,
          ),
          if (divider) Divider(height: 1, color: colors.border),
          if (isExpanded) content,
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.actions,
    required this.height,
  });

  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> actions;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: onToggle,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_right_rounded,
                size: 18,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: colors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
