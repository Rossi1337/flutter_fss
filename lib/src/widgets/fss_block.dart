import 'package:flutter/material.dart';
import 'package:fss/src/parser/fss_rule_block.dart';
import 'package:fss/src/widgets/fss_widget.dart';
import 'package:fss/src/widgets/fss_widget_builder.dart';

/// A container that will automatically apply some styles of the applicable [FssRuleBlock]
///
/// This will resolve the applicable rule from the [FssTheme] and then apply some
/// styles to the container like: padding, margin, border, background, box-shadow...
/// So everything which is applicable for a container directly.
class FssBlock extends FssWidget {
  final DecorationImage? imageOverride;

  /// A builder to create the child widget.
  ///
  /// The builder will have access to the applicable FssRule containing all
  /// the styles. Use this if you want to configure your widget with styles.
  /// If a [child] is defined the builder is ignored.
  final FssWidgetBuilder? builder;

  /// Creates a new [FssBlock] with the given [builder] method.
  const FssBlock({
    super.key,
    super.child,
    this.builder,
    super.fssType,
    super.fssID,
    super.fssClass,
    super.fssAttributes,
  }) : imageOverride = null;

  /// Creates a new [FssBlock] with the given [imageOverride].
  const FssBlock.withImage({
    super.key,
    required this.imageOverride,
    super.fssType,
    super.fssID,
    super.fssClass,
    super.fssAttributes,
  }) : builder = null;

  @override
  Widget buildContent(BuildContext context, FssRuleBlock applicableRule) {
    final rule = applicableRule;
    Widget? content = const SizedBox.shrink();
    if (rule.contentVisible) {
      content = child ?? builder?.call(context, applicableRule);
    }

    final boxShadow = rule.boxShadow;
    return Container(
      padding: rule.padding,
      margin: rule.margin,
      width: rule.width,
      height: rule.height,
      transform: rule.transformMatrix,
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        boxShadow: boxShadow == null ? null : [boxShadow],
        color: rule.backgroundColor,
        image: imageOverride ?? rule.backgroundImage,
        gradient: rule.backgroundGradient,
        border: rule.border,
        borderRadius: rule.borderRadius,
      ),
      alignment: rule.alignment,
      constraints: rule.constraints,
      child: content,
    );
  }
}
