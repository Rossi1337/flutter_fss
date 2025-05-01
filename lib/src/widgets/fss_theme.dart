import 'package:flutter/material.dart';
import 'package:fss/src/default/fss_html_css.dart';
import 'package:fss/src/material/material_bridge.dart';
import 'package:fss/src/parser/fss_parser.dart';
import 'package:fss/src/parser/fss_property.dart';
import 'package:fss/src/parser/fss_rule.dart';
import 'package:fss/src/parser/fss_rule_block.dart';
import 'package:fss/src/parser/fss_stylesheet.dart';

/// A widget to install a css like stylesheet into the widget tree as a theme.
/// All fss widgets will then access this stylesheet to resolve rules and
/// to apply the styles to them. To create fss styling aware widgets
/// use the [Fss] factory class.
///
/// You can retrieve the current theme from the BuildContext via [FssTheme.of]
///
/// Via the [resolveStyles] method you can programmatically resolve all rules
/// for a given element type, ID and list of classes but normally an FssWidget
/// will resolve for you automatically the rules into a set of styles and you
/// do not need to invoke this manually.
///
class FssTheme extends InheritedWidget {
  final FlutterStyleSheet stylesheet;

  /// Parses the rules from the given String
  /// If you specify both the stylesheet and rules then we parse first
  /// the stylesheet and add the rules afterwards
  FssTheme({
    super.key,
    String? stylesheet = '',
    List<FssRule>? rules,
    required super.child,
    FssRuleBlock? systemDefaults,
  }) : stylesheet = FlutterStyleSheet(
          stylesheet: stylesheet,
          rules: rules,
          systemDefaults: systemDefaults,
        );

  // Creates a theme with some system defaults derived from the Material Theme
  // Additionally this will add variables and some default rules.
  factory FssTheme.withAppDefaults({
    Key? key,
    required BuildContext context,
    FssRuleBlock? defaultOverrides,
    required String stylesheet,
    required Widget child,
  }) {
    // start with initial values
    FssRuleBlock defaults = FssProperty.getInitialValues();

    // extract variables and default values from material design
    final FssRuleBlock materialDefaults = getSystemDefaults(context);
    defaults = defaults.merge(materialDefaults);

    // than merge the given system defaults on top
    if (defaultOverrides != null) {
      defaults = defaults.merge(defaultOverrides);
    }

    // Build some standard rules matching the material design
    final defaultRules = getSystemDefaultRules(context);

    return FssTheme(
      key: key,
      stylesheet: stylesheet,
      rules: defaultRules,
      systemDefaults: defaults,
      child: child,
    );
  }

  // Creates a theme with some HTML defaults derived from a internal html.css
  factory FssTheme.withHtmlDefaults({
    Key? key,
    FssRuleBlock? defaultOverrides,
    required String stylesheet,
    required Widget child,
  }) {
    // start with initial values
    FssRuleBlock defaults = FssProperty.getInitialValues();

    // than merge the given system defaults on top
    if (defaultOverrides != null) {
      defaults = defaults.merge(defaultOverrides);
    }

    // Load html.css
    final List<FssRule> rules = [
      ...parseStylesheet(htmlCss),
      ...parseStylesheet(stylesheet)
    ];

    return FssTheme(
      key: key,
      stylesheet: stylesheet,
      rules: rules,
      systemDefaults: defaults,
      child: child,
    );
  }

  /// Builds a special FssRule that can be used as defaults for an FssTheme.
  /// It will set some initial styles and add many of the Material theme values
  /// as variables.
  static FssRuleBlock getSystemDefaults(BuildContext context) {
    return FssRuleBlock(MaterialThemeBridge.extractStylesAndVars(context));
  }

  /// Creates some default rules matching the current Material Theme.
  static List<FssRule> getSystemDefaultRules(BuildContext context) {
    return MaterialThemeBridge.extractDefaultRules(context);
  }

  /// Find the currently applicable FssTheme in the widget tree.
  static FssTheme? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FssTheme>();
  }

  /// Create a copy of the current theme with additional rules.
  FssTheme copyWith({
    Key? key,
    String? stylesheet = '',
    List<FssRule>? rules,
    required Widget child,
    FssRuleBlock? systemDefaults,
  }) {
    // original rules then add on top
    final newRuleSet = [
      ...this.stylesheet.rules,
      ...?rules,
      ...parseStylesheet(stylesheet),
    ];

    // Original defaults then the given defaults on top.
    final newDefaults = this.stylesheet.systemDefaults.merge(systemDefaults);

    return FssTheme(
      key: key,
      systemDefaults: newDefaults,
      rules: newRuleSet,
      child: child,
    );
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;

  /// Resolves and merges all the rules that match the given classes list, type
  /// and FSS ID. All matching rules will be processed and merged into a final
  /// combined rule block.
  /// If your stylesheet contains media query rules you
  /// need to provide MediaQueryData otherwise these rules will not be resolved.
  /// If you do not provide parentStyles then no property inheritance will take
  /// place and if a property is not found in the matching rules it will fallback
  /// to the default value for that property.
  FssRuleBlock resolveStyles({
    String matchType = '',
    String matchId = '',
    String matchClasses = '',
    Map<String, String> attributes = const {},
    FssRuleBlock? parentStyles,
    MediaQueryData? media,
  }) {
    return stylesheet.resolveStyles(
      matchType: matchType,
      matchId: matchId,
      matchClasses: matchClasses,
      matchAttributes: attributes,
      parentStyles: parentStyles,
      media: media,
    );
  }

  /// When invoked with diagnostic level "fine" it will generate the
  /// style sheet debug info too.
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    var result = super.toString(minLevel: minLevel);
    if (minLevel == DiagnosticLevel.fine) {
      result += '\n${stylesheet.getDebugThemeInfo()}';
    }
    return result;
  }
}
