import 'package:flutter/foundation.dart';
import 'package:fss/src/parser/fss_rule_block.dart';
import 'package:fss/src/parser/fss_selector.dart';

/// Specifies a FSS rule consisting of a selector and a set of properties.
///
/// The list of properties is stored in a [FssRuleBlock]
@immutable
class FssRule {
  /// The selector for this rule.
  final FssSelector selector;

  /// The properties for this rule.
  final FssRuleBlock properties;

  const FssRule(this.selector, this.properties);

  @override
  String toString() => '$selector\n$properties';
}
