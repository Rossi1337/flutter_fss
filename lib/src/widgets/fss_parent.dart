import 'package:flutter/material.dart';
import 'package:fss/src/parser/fss_rule_block.dart';

/// This widget is a invisible node that is injected into the widget tree to support
/// style inheritance.
///
class FssParent extends InheritedWidget {
  final FssRuleBlock? applicableStyles;

  /// Creates a new [FssParent] with the given [applicableStyles].
  const FssParent({
    super.key,
    required super.child,
    required this.applicableStyles,
  });

  @override
  bool updateShouldNotify(covariant FssParent oldWidget) {
    // Only notify dependents when the resolved styles actually changed.
    // Rebuilding a widget does not mean its styles changed, and notifying
    // unconditionally would mark every descendant that depends on this
    // FssParent dirty, cascading rebuilds through the whole subtree.
    return oldWidget.applicableStyles != applicableStyles;
  }

  /// Returns the [FssRuleBlock] that is applicable to this [context].
  static FssRuleBlock? of(BuildContext context) {
    final c = context.dependOnInheritedWidgetOfExactType<FssParent>();
    return c?.applicableStyles;
  }
}
