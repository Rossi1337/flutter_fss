import 'package:flutter/material.dart';
import 'package:fss/src/parser/fss_rule_block.dart';
import 'package:fss/src/widgets/fss_widget.dart';

/// A styleable text inline widget.
///
/// This will set the [TextStyle] of the widget from the stylesheet.
class FssSpan extends FssWidget {
  final String data;

  /// Creates a new [FssSpan] with the given [data].
  /// To style the widget you can speficy a [fssType], [fssID] and [fssClass].
  const FssSpan(
    this.data, {
    super.key,
    super.fssType,
    super.fssID,
    super.fssClass,
    super.fssAttributes,
  });

  @override
  Widget buildContent(BuildContext context, FssRuleBlock applicableRule) {
    return Text(
      applicableRule.transformText(data),
      style: applicableRule.textStyle,
      overflow: applicableRule.wrapText ? null : applicableRule.textOverflow,
      softWrap: applicableRule.wrapText,
      textDirection: applicableRule.direction,
    );
  }
}
