import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

/// Represents a style sheet containing a set of rules.
class FlutterStyleSheet {
  final List<FssRule> _rules = [];

  /// The maximum number of resolved style blocks kept in the cache.
  /// Once this limit is reached the oldest entry is evicted.
  static const int _maxCachedResolutions = 512;

  /// A cache for the resolved styles keyed by the inputs of the resolution.
  ///
  /// Resolution (matching, sorting by specificity and merging of all rules)
  /// is the most expensive part of this library and it is invoked on every
  /// build of every fss widget. If the inputs are the same the result is
  /// identical, so the result is cached here to avoid re-resolving it.
  ///
  /// Insertion order is kept so that the oldest entry can be evicted
  /// once the cache reaches [_maxCachedResolutions] entries.
  final Map<_ResolvedStylesKey, FssRuleBlock> _resolvedStylesCache = {};

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

    // Look up the resolved styles in the cache. The cache key contains all
    // values that influence the result, so a cache hit is always valid.
    final cacheKey = _ResolvedStylesKey(
      matchType: matchType,
      matchId: idToMatch,
      matchClasses: matchClasses,
      matchAttributes: matchAttributes,
      parentStyles: parentStyles,
      media: media,
    );
    final cached = _resolvedStylesCache[cacheKey];
    if (cached != null) {
      return cached;
    }

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

    // Remember the result in the cache and evict the oldest entry
    // if the cache exceeds its size limit.
    _resolvedStylesCache[cacheKey] = result;
    if (_resolvedStylesCache.length > _maxCachedResolutions) {
      _resolvedStylesCache.remove(_resolvedStylesCache.keys.first);
    }

    return result;
  }

  /// Removes all cached resolved styles.
  ///
  /// This is useful if you change the rules or the system defaults of this
  /// style sheet at run time and you want to make sure that all subsequent
  /// resolutions start from scratch.
  void clearResolvedStylesCache() {
    _resolvedStylesCache.clear();
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

/// Cache key for the resolved styles cache.
///
/// [operator ==] and [hashCode] consider every value that influences the
/// resolution result, so an equal key always refers to the same result.
///
/// [parentStyles] is compared by value via [FssRuleBlock.operator ==],
/// which recursively walks the property maps and the parent chain.
class _ResolvedStylesKey {
  _ResolvedStylesKey({
    required this.matchType,
    required this.matchId,
    required this.matchClasses,
    required this.matchAttributes,
    required this.parentStyles,
    required this.media,
  });

  final String matchType;
  final String matchId;
  final String matchClasses;
  final Map<String, String> matchAttributes;
  final FssRuleBlock? parentStyles;
  final MediaQueryData? media;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! _ResolvedStylesKey) {
      return false;
    }
    return other.matchType == matchType &&
        other.matchId == matchId &&
        other.matchClasses == matchClasses &&
        _mapEquals(other.matchAttributes, matchAttributes) &&
        other.parentStyles == parentStyles &&
        other.media == media;
  }

  @override
  int get hashCode => Object.hash(
        matchType,
        matchId,
        matchClasses,
        _mapHash(matchAttributes),
        parentStyles,
        media,
      );

  @override
  String toString() =>
      '_ResolvedStylesKey($matchType, $matchId, $matchClasses, $matchAttributes, $parentStyles, $media)';

  /// Order-independent content comparison for [matchAttributes].
  static bool _mapEquals(Map<String, String>? a, Map<String, String>? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  /// Order-independent hash consistent with [_mapEquals].
  /// Uses addition so that the entry order does not influence the result.
  static int _mapHash(Map<String, String>? map) {
    if (map == null) {
      return 0;
    }
    var hash = 17;
    for (final entry in map.entries) {
      hash += Object.hash(entry.key, entry.value);
    }
    return hash;
  }
}
