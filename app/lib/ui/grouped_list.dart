import 'package:flutter/material.dart';

/// Corner radii of a grouped list: large on the outside of a group, small
/// between its items.
const double kGroupOuterRadius = 20;
const double kGroupInnerRadius = 4;
const double kGroupGap = 2;

/// One row of a grouped list: a `surfaceContainer` tile with 2 dp gaps to its
/// neighbours, 20 dp corners on the first and last row of a group and 4 dp
/// corners between rows. A selected row uses `secondaryContainer`.
class GroupedTile extends StatelessWidget {
  const GroupedTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.isFirst = true,
    this.isLast = true,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool isFirst;
  final bool isLast;

  /// The shape for a row at this position in its group.
  static BorderRadius radiusFor({
    required bool isFirst,
    required bool isLast,
  }) => BorderRadius.vertical(
    top: Radius.circular(isFirst ? kGroupOuterRadius : kGroupInnerRadius),
    bottom: Radius.circular(isLast ? kGroupOuterRadius : kGroupInnerRadius),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, isLast ? 0 : kGroupGap),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: radiusFor(isFirst: isFirst, isLast: isLast),
        ),
        tileColor: selected
            ? scheme.secondaryContainer
            : scheme.surfaceContainer,
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
