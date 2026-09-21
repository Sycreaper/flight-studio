import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// One option of a [SettingsDropdown].
class SettingsDropdownItem<T> {
  const SettingsDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// A compact dropdown control styled to match the settings tiles — the same
/// look as the simulator-type picker in the add-simulator dialog. Renders the
/// current label with a chevron; tapping opens a popup with all [items]
/// (scrolls automatically when the list is long, e.g. font families).
class SettingsDropdown<T> extends StatelessWidget {
  const SettingsDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 190,
    this.maxMenuHeight = 360,
  });

  final T value;
  final List<SettingsDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final double width;
  final double maxMenuHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final current = items.cast<SettingsDropdownItem<T>?>().firstWhere(
      (i) => i?.value == value,
      orElse: () => null,
    );
    return PopupMenuButton<T>(
      initialValue: value,
      color: colors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.border),
      ),
      elevation: 8,
      constraints: BoxConstraints(
        minWidth: width + 40,
        maxHeight: maxMenuHeight,
      ),
      onSelected: onChanged,
      itemBuilder: (ctx) => [
        for (final item in items) _checkedItem(item, colors),
      ],
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceLowered,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                current?.label ?? '',
                style: TextStyle(fontSize: 12.5, color: colors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  CheckedPopupMenuItem<T> _checkedItem(
    SettingsDropdownItem<T> item,
    AppColors colors,
  ) {
    final selected = item.value == value;
    return CheckedPopupMenuItem<T>(
      value: item.value,
      checked: selected,
      child: Text(
        item.label,
        style: TextStyle(
          fontSize: 13,
          color: selected ? colors.accent : colors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
