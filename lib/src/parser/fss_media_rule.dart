import 'package:flutter/foundation.dart';
import 'package:fss/src/parser/fss_media_selector.dart';
import 'package:fss/src/parser/fss_rule.dart';
import 'package:fss/src/parser/fss_rule_block.dart';

/// A special rule container for a media block.
///
/// It contains internally a list of sub rules. If the media rule's
/// selector matches only then the sub rules are evaluated.
@immutable
class FssMediaRule extends FssRule {
  /// The list of sub rules contained in this media rule.
  final List<FssRule> subRules;

  /// Creates a new [FssMediaRule] with the given [mediaQuery] and [subRules].
  FssMediaRule(String mediaQuery, this.subRules)
      : super(
          FssMediaSelector(mediaQuery: mediaQuery),
          FssRuleBlock(const {}),
        );

  @override
  String toString() {
    final result = StringBuffer();
    result
      ..writeln('// BEGIN @MEDIA BLOCK')
      ..write(selector)
      ..writeln(' {')
      ..writeln();
    subRules.forEach(result.writeln);
    result.writeln('} // END @MEDIA BLOCK');

    return result.toString();
  }
}
