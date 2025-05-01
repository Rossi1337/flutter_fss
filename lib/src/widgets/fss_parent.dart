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
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }

  /// Returns the [FssRuleBlock] that is applicable to this [context].
  static FssRuleBlock? of(BuildContext context) {
    final c = context.dependOnInheritedWidgetOfExactType<FssParent>();
    return c?.applicableStyles;
  }
}
