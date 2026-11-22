import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One label/value line of a fact sheet (inspector airport dossier,
/// aircraft panel). Shared atom so every fact table in the app reads the
/// same: fixed-width muted label left, value right, hairline rhythm.
class FactRow extends StatelessWidget {
  const FactRow({super.key, required this.label, required this.value,
      this.muted = false});

  final String label;
  final String value;

  /// Renders the value in the secondary tone (e.g. computed/derived info).
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: colors.textDisabled,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: muted ? colors.textSecondary : colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
