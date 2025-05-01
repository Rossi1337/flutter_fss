import 'package:flutter/foundation.dart';
import 'package:fss/fss.dart';

/// Small helper class to store a rule match in a list and to allow to sort them
/// by specificity / order.
@immutable
class FssRuleMatch implements Comparable<FssRuleMatch> {
  final FssRule rule;
  final FssSpecificity specificity;
  final int order;

  /// Constructor
  const FssRuleMatch(this.rule, this.specificity, this.order);

  /// compare first by specificity and then by order
  @override
  int compareTo(FssRuleMatch other) {
    final result = specificity.compareTo(other.specificity);
    return result == 0 ? order.compareTo(other.order) : result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FssRuleMatch &&
          runtimeType == other.runtimeType &&
          rule == other.rule &&
          specificity == other.specificity &&
          order == other.order;

  @override
  int get hashCode => Object.hash(rule, specificity, order);
}
