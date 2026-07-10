import 'package:flutter/material.dart';

import '../../../features/flights/flight_record.dart';
import '../theme/app_colors.dart';

/// A JetBrains-IDEA "Project"-style tree listing saved flight plans, shown in
/// the left drawer of a Map tab. When there are no plans, the whole area is a
/// tap target that triggers [onCreate] to open a new flight-plan form tab.
class FlightPlanTree extends StatelessWidget {
  const FlightPlanTree({
    super.key,
    this.plans = const [],
    required this.onCreate,
    this.onOpenPlan,
  });

  final List<FlightRecord> plans;
  final VoidCallback onCreate;
  final ValueChanged<FlightRecord>? onOpenPlan;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return _EmptyPlans(onCreate: onCreate);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CreateRow(onCreate: onCreate),
        const SizedBox(height: 4),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: [
              _TreeNode(
                icon: Icons.flight_rounded,
                label: 'Flight Plans (${plans.length})',
                bold: true,
                expanded: true,
                children: plans
                    .map((p) => _PlanLeaf(plan: p, onTap: () => onOpenPlan?.call(p)))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateRow extends StatelessWidget {
  const _CreateRow({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            'FLIGHT PLANS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: colors.accent,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'New flight plan',
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 16),
            color: colors.textSecondary,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  const _EmptyPlans({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: onCreate,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.post_add_rounded,
              size: 30,
              color: colors.textDisabled,
            ),
            const SizedBox(height: 10),
            Text(
              'No flight plans',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Click to create one',
              style: TextStyle(fontSize: 11, color: colors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tree node with optional expandable children, mirroring IDEA's project
/// view indentation and chevron affordance.
class _TreeNode extends StatefulWidget {
  const _TreeNode({
    required this.icon,
    required this.label,
    required this.children,
    this.bold = false,
    this.expanded = false,
  });

  final IconData icon;
  final String label;
  final List<Widget> children;
  final bool bold;
  final bool expanded;

  @override
  State<_TreeNode> createState() => _TreeNodeState();
}

class _TreeNodeState extends State<_TreeNode> {
  late bool _expanded = widget.expanded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.expand_more_rounded
                      : Icons.chevron_right_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 2),
                Icon(widget.icon, size: 15, color: colors.accent),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          widget.bold ? FontWeight.w700 : FontWeight.w400,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.children,
            ),
          ),
      ],
    );
  }
}

class _PlanLeaf extends StatefulWidget {
  const _PlanLeaf({required this.plan, required this.onTap});
  final FlightRecord plan;
  final VoidCallback onTap;

  @override
  State<_PlanLeaf> createState() => _PlanLeafState();
}

class _PlanLeafState extends State<_PlanLeaf> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _hovering
                ? colors.accent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 14, color: colors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.plan.route,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: _hovering ? colors.accent : colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
