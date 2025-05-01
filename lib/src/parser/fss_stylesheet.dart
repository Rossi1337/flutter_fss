import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

/// Represents a style sheet containing a set of rules.
class FlutterStyleSheet {
  final List<FssRule> _rules = [];

  /// The list of rules in this style sheet.
  List<FssRule> get rules {
    return List.unmodifiable(_rules);
  }

  FssRuleBlock _systemDefaults = FssRuleBlock(const {});

  /// Defines the system defaults for all styles. Use this to initialize values.
  /// These will then be used when no other rule is overriding them.
  FssRuleBlock get systemDefaults => _systemDefaults;

  /// The default constructor for the [FlutterStyleSheet] class.
  /// Provides a way to create a style sheet with an optional stylesheet string,
  /// a list of rules, and system defaults.
  FlutterStyleSheet({
    String? stylesheet = '',
    List<FssRule>? rules,
    FssRuleBlock? systemDefaults,
  }) {
    _systemDefaults = systemDefaults ?? FssProperty.getInitialValues();

    if (rules != null) {
      _rules.addAll(rules);
    }
    // Add everything from the style sheet
    _rules.addAll(parseStylesheet(stylesheet));
  }

  /// Resolves and merges all the rules that match the given classes string and
  /// FSS ID. All matching rules will be processed and merged into a final
  /// combined rule.
  FssRuleBlock resolveStyles({
    String matchType = '',
    String matchId = '',
    String matchClasses = '',
    Map<String, String> matchAttributes = const {},
    FssRuleBlock? parentStyles,
    MediaQueryData? media,
  }) {
    // TODO suport attributes in the selector

    var idToMatch = matchId;
    if (idToMatch.isNotEmpty && !idToMatch.startsWith('#')) {
      idToMatch = '#$idToMatch';
    }

    // split into single classes and add . in front of each
    final matchClassesAsList =
        matchClasses.split(RegExp(r'\s+')).map((e) => '.${e.trim()}').toList();

    // first check all the @Media query rules
    final List<FssRule> rulesToMatch = [];
    for (final rule in _rules) {
      if (rule is FssMediaRule) {
        if (rule.selector.getSpecificity('', '', [], media) >
            FssSpecificity.noMatch) {
          // print('-> @Media matched: ${rule.selector}');
          rulesToMatch.addAll(rule.subRules);
        }
      } else {
        rulesToMatch.add(rule);
      }
    }

    // now check all the rules
    final List<FssRuleMatch> matchedRules = [];
    int ruleNo = 0;
    for (final rule in rulesToMatch) {
      final specificity = rule.selector.getSpecificity(
          matchType, idToMatch, matchClassesAsList, media, matchAttributes);
      if (specificity > FssSpecificity.noMatch) {
        matchedRules.add(FssRuleMatch(rule, specificity, ruleNo));
      }
      ruleNo++;
    }

    // Sort by specificity
    matchedRules.sort();

    // Now merge properties of all the matched rules
    // Start with an empty property set with parent and system defaults set
    var result = FssRuleBlock(
      const {},
      parent: parentStyles,
      initialValues: systemDefaults,
    );

    for (final match in matchedRules) {
      result = result.merge(match.rule.properties);
    }

    // Add some values from media
    final screenSize = media?.size;
    if (screenSize != null) {
      final vwName = FssProperty.fss_screen_width.name;
      final vhName = FssProperty.fss_screen_height.name;
      result = result.merge(
        FssRuleBlock({
          vwName: FssPropertyValue(vwName, '${screenSize.width}px'),
          vhName: FssPropertyValue(vhName, '${screenSize.height}px'),
        }),
      );
    }

    return result;
  }

  /// Create a copy of the current stylesheet with additional rules added.
  FlutterStyleSheet copyWith({
    String? stylesheet,
    List<FssRule>? rules,
    FssRuleBlock? systemDefaults,
  }) {
    // original rules then add on top
    final List<FssRule> newRuleSet = [
      ..._rules,
      ...?rules,
      ...parseStylesheet(stylesheet)
    ];

    return FlutterStyleSheet(
      systemDefaults: systemDefaults,
      rules: newRuleSet,
    );
  }

  /// Gets a debug summary of all the rules and defaults in this style sheet.
  String getDebugThemeInfo() {
    final result = StringBuffer()
      ..writeln('System Defaults:')
      ..writeln('----------------------------------------------------------')
      ..writeln(systemDefaults)
      ..writeln('Rules:')
      ..writeln('----------------------------------------------------------');
    _rules.forEach(result.writeln);
    return result.toString();
  }
}
