import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

/// Abstract widget that resolves the applicable [FssRuleBlock] for you and
/// allows you to configure any widget with it. When you inherit from
/// this class you need to implement the [buildContent] method.
///
abstract class FssWidget extends StatelessWidget {
  /// A child widget.
  ///
  /// The child widget encapsulated in this styleable widget.
  final Widget? child;

  /// FSS class names used to resolve the styles for this container.
  ///
  /// See [FssTheme.resolveStyles] for details how styles are resolved.
  final String? fssClass;

  /// An style ID that can be used to resolve rules from the style sheet.
  final String? fssID;

  /// This specifies the type of the widget that can be used to resolve rules
  /// from the style sheet.
  final String? fssType;

  /// A map of additional attributes that can be used to resolve rules from the style sheet.
  final Map<String, String> fssAttributes;

  /// Creates a new [FssWidget] with the given [child], [fssType], [fssID], [fssClass]
  /// and additional [fssAttributes].
  const FssWidget({
    super.key,
    this.child,
    this.fssType,
    this.fssID,
    this.fssClass,
    this.fssAttributes = const {},
  });

  @override
  Widget build(BuildContext context) {
    final applicableStyles = resolveApplicableStyles(
      context: context,
      clazz: fssClass,
      id: getIDForResolve(),
      fssType: fssType,
    );

    final content = !applicableStyles.visible
        ? const SizedBox.shrink()
        : buildContent(context, applicableStyles);

    return FssParent(
      applicableStyles: applicableStyles,
      child: Builder(builder: (c) => content),
    );
  }

  /// Gets the ID that is used to resolve rules.
  /// This is either set fssID otherwise we try to build it from the widget [Key]
  /// if that one is a instance of [ValueKey]
  String getIDForResolve() {
    if (fssID != null) {
      return fssID!;
    }
    // Try as fallback to convert the key to an "ID"
    if (key is ValueKey) {
      final value = (key! as ValueKey).value;
      return value?.toString() ?? '';
    }
    return '';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('fssID', fssID, defaultValue: null));
    properties.add(StringProperty('fssClass', fssClass, defaultValue: null));
    properties.add(StringProperty('fssType', fssType, defaultValue: null));
  }

  /// Overwrite this method to build the content for the widget
  Widget buildContent(BuildContext context, FssRuleBlock applicableStyles);
}
