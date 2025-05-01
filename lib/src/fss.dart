/// This library will provide some base classes for the Flutter Style Sheet
/// It offers all the building blocks to model the theme and its rules and
/// to wrap or create Fss styled widgets.
///
/// Some entry points are [FssTheme] to install a fss style sheet based theme
/// into your widget tree. Then you can use the [Fss] which offers factory methods
/// to create styleable widgets.
///
/// To create your own styleable widgets either wrap them into [FssBlock] or extend
/// [FssWidget].
///

// ignore_for_file: prefer_const_constructors_in_immutables

library;

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

/// This is mainly a factory to create widgets which can be then styled from
/// a style sheet file.
/// If offers static factory methods to create common elements which are imitating popular
/// elements of HTML like for example: Fss.div, Fss.p, Fss.img ...
///
/// Alternatively you can specify the element type as generic constructor parameter to
/// the Fss constructor. For exmaple like this: `Fss<b>()`.
///
class Fss<T extends FssHtmlTag> extends FssWidget {
  /// Content or child Widget
  ///
  final Object _content;

  /// Build a FssWidget from a HTML element.
  ///
  /// The generic type [T] is the HTML element type. This will be used to resolve the styles.
  /// The [c] parameter is the content of the widget.
  /// This can be a [Widget] or a [String]. If it is a [String] it will be wrapped in a [FssSpan].
  /// The parameter [id] is the id of the element and [clazz] is a list of classes. Additinal attributes
  /// can be passed in the [attr] parameter.
  Fss({
    super.key,
    String? id,
    String? clazz,
    Map<String, String>? attr,
    required Object c,
  })  : _content = c,
        super(
          child: c is Widget ? c : null,
          fssID: id,
          fssClass: clazz,
          fssType: T.toString().toLowerCase(),
          fssAttributes: attr ?? const {},
        );

  @override
  Widget buildContent(BuildContext context, FssRuleBlock applicableStyles) {
    if (applicableStyles.display == 'block' || child != null) {
      return FssBlock(
        key: key,
        fssType: fssType,
        fssID: fssID,
        fssClass: fssClass,
        fssAttributes: fssAttributes,
        child: (_content is Widget ? _content : FssSpan(_content.toString()))
            as Widget?,
      );
    }

    return FssSpan(
      _content.toString(),
      key: key,
      fssType: fssType,
      fssID: fssID,
      fssClass: fssClass,
      fssAttributes: fssAttributes,
    );
  }

  /// Allows you to build you own widget with Fss styles applied.
  /// This allows you to specify for your widget an type, id and a list of classes.
  /// The builder will then be invoked and will give you access to the resolved
  /// style properties that you can use then to configure your widget.
  static Widget styled({
    Key? key,
    String? id,
    String? fssType,
    String? clazz,
    Map<String, String>? attr,
    required FssWidgetBuilder builder,
  }) =>
      _FssBuilder(
        key: key,
        builder: builder,
        fssType: fssType,
        fssID: id,
        fssClass: clazz,
        fssAttributes: attr ?? const {},
      );

  /// Builds a text widget with a TextTheme applied from the style sheet.
  static FssSpan span(
    String data, {
    Key? key,
    String? fssType,
    String? id,
    String? clazz,
    Map<String, String>? attr,
  }) =>
      FssSpan(
        data,
        key: key,
        fssType: fssType ?? FssType.span.name,
        fssID: id,
        fssClass: clazz,
        fssAttributes: attr ?? const {},
      );

  /// Builds a container widget similar to the HTML div element but you can
  /// specify an own "type".
  static FssBlock block({
    Key? key,
    String? id,
    String? fssType,
    String? clazz,
    Map<String, String>? attr,
    Widget? child,
    FssWidgetBuilder? builder,
  }) =>
      FssBlock(
        key: key,
        builder: builder,
        fssType: fssType,
        fssID: id,
        fssClass: clazz,
        fssAttributes: attr ?? const {},
        child: child,
      );

  /// Builds a list widget similar to the HTML ul element.
  static Widget ul({
    Key? key,
    String? id,
    String? clazz,
    Map<String, String>? attr,
    required List<Widget> children,
  }) =>
      FssList(
        key: key,
        fssType: FssType.ul.name,
        fssID: id,
        fssClass: clazz,
        fssAttributes: attr ?? const {},
        children: children,
      );

  /// Builds a list widget similar to the HTML ol element.
  static Widget ol({
    Key? key,
    String? id,
    String? clazz,
    Map<String, String>? attr,
    required List<Widget> children,
  }) =>
      FssList(
        key: key,
        fssType: FssType.ol.name,
        fssID: id,
        fssClass: clazz,
        fssAttributes: attr ?? const {},
        children: children,
      );

  /// Builds a list widget similar to the HTML li element.
  static Widget li({
    Key? key,
    String? id,
    String? fssType,
    String? clazz,
    Map<String, String>? attr,
    required Widget child,
  }) =>
      FssListItem(
        key: key,
        fssType: FssType.li.name,
        fssID: id,
        fssClass: clazz,
        fssAttributes: attr ?? const {},
        child: child,
      );

  /// Builds a container widget similar to the HTML div element.
  static FssBlock div({
    Key? key,
    String? id,
    String? clazz,
    Map<String, String>? attr,
    Widget? child,
    FssWidgetBuilder? builder,
  }) =>
      block(
        key: key,
        child: child,
        builder: builder,
        fssType: FssType.div.name,
        id: id,
        clazz: clazz,
        attr: attr,
      );

  /// Builds a container widget similar to the HTML img element.
  static FssBlock img({
    Key? key,
    String? id,
    String? clazz,
    Map<String, String>? attr,
    required ImageProvider src,
  }) =>
      FssBlock.withImage(
        key: key,
        imageOverride: DecorationImage(image: src, fit: BoxFit.fill),
        fssType: FssType.img.name,
        fssID: id,
        fssClass: clazz,
        fssAttributes: attr ?? const {},
      );

  /// Builds a container widget similar to the HTML hr element.
  /// You can style the "border" property in the fss file to change its look.
  static FssBlock hr({
    Key? key,
    String? id,
    String? clazz,
    Map<String, String>? attr,
  }) =>
      block(
        key: key,
        fssType: FssType.hr.name,
        id: id,
        clazz: clazz,
        attr: attr,
        child: const SizedBox.shrink(),
      );

  /// Builds a container widget similar to the HTML p element.
  static FssBlock p({
    Key? key,
    String? id,
    String? clazz,
    Map<String, String>? attr,
    Widget? child,
    FssWidgetBuilder? builder,
  }) =>
      block(
        key: key,
        child: child,
        builder: builder,
        fssType: FssType.p.name,
        id: id,
        clazz: clazz,
        attr: attr,
      );
}

/// A builder that will allow you to style your component.
///
/// This will resolve the applicable rule from the [FssTheme] and then invoke
/// the builder.
class _FssBuilder extends FssWidget {
  /// A builder to create the child widget.
  ///
  /// The builder will have access to the applicable FssRule containing all
  /// the styles. Use this if you want to configure your widget with styles.
  /// If a [child] is defined the builder is ignored.
  final FssWidgetBuilder builder;

  const _FssBuilder({
    super.key,
    required this.builder,
    super.fssType,
    super.fssID,
    super.fssClass,
    super.fssAttributes,
  });

  @override
  Widget buildContent(BuildContext context, FssRuleBlock applicableRule) {
    return builder(context, applicableRule);
  }
}

/// Finds the applicable styles to use for this widget.
/// If no class is set on this container look up the hirarchy.
/// This will merge the styles from the parent and the current widget.
/// This will also resolve the media query rules if any are defined in the stylesheet.
/// The result is a set of merged styles that can be used to configure the widget.
FssRuleBlock resolveApplicableStyles({
  required BuildContext context,
  String? fssType,
  String? id,
  String? clazz,
  Map<String, String> attributes = const {},
}) {
  final stylesheet = FssTheme.of(context);
  if (stylesheet == null) {
    throw const FssParseException(
      'No FssTheme found in the widget tree. Cannot resolve styles.',
    );
  }

  // Used to resolve media query rules.
  final media = MediaQuery.maybeOf(context);

  // Find parent container and get its styles for inheritance
  final parentStyles = FssParent.of(context);

  return stylesheet.resolveStyles(
    matchId: id ?? '',
    matchClasses: clazz ?? '',
    matchType: fssType ?? '',
    parentStyles: parentStyles,
    attributes: attributes,
    media: media,
  );
}
