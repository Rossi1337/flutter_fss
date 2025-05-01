import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:fss/src/parser/fss_base.dart';
import 'package:fss/src/parser/fss_parser.dart';
import 'package:fss/src/parser/fss_property_value.dart';
import 'package:fss/src/parser/fss_selector.dart';

/// A Special selector for a media rules.
@immutable
class FssMediaSelector extends FssSelector {
  final String mediaQuery;

  /// Creates a new [FssMediaSelector] with the given [mediaQuery].
  const FssMediaSelector({required this.mediaQuery}) : super(type: mediaQuery);

  /// Checks only the given media against the media rule of this selector.
  /// Return 1 if the media features are matching else 0.
  @override
  FssSpecificity getSpecificity(
    String? matchType,
    String? matchId,
    List<String>? matchClasses, [
    MediaQueryData? media,
    Map<String, String>? matchAttributes,
  ]) {
    if (media == null) {
      return FssSpecificity.noMatch;
    }
    bool matched = true;
    // CSS syntax @media only screen and (max-width: 600px)
    // ignore the media type and only look at the features.
    // We only support AND combined features for now.
    int start = mediaQuery.indexOf('(');
    while (start != -1 && matched) {
      final end = mediaQuery.indexOf(')', start);
      final feature = mediaQuery.substring(start + 1, end).trim();
      start = mediaQuery.indexOf('(', end + 1);

      String name = feature;
      String operator = '=';
      String value = '';
      final match = RegExp(r'([a-z-]+)\s*([<=>:]+)\s*([a-z0-9/-\s]+)')
          .firstMatch(feature);
      if (match != null) {
        name = match.group(1)!;
        operator = match.group(2)!;
        value = match.group(3)!;
      }
      if (operator == ':') operator = '=';
      if (name.startsWith('min-')) {
        name = name.substring(4);
        operator = '>';
      }
      if (name.startsWith('max-')) {
        name = name.substring(4);
        operator = '<';
      }

      switch (name) {
        case 'width':
          final expected = parseSizeDef(FssPropertyValue(name, value))
              .getPixelSize(FssBase.fallback);
          matched = _compare(media.size.width, operator, expected);
        case 'height':
          final expected = parseSizeDef(FssPropertyValue(name, value))
              .getPixelSize(FssBase.fallback);
          matched = _compare(media.size.height, operator, expected);
        case 'aspect-ratio':
          final parts = value.split('/'); // support value like this 16/9
          final expected = parts.length > 1
              ? (double.parse(parts[0].trim()) / double.parse(parts[1].trim()))
              : parseSizeDef(FssPropertyValue(name, value))
                  .getPixelSize(FssBase.fallback);
          matched = _compare(
            media.size.width / media.size.height,
            operator,
            expected,
          );
        case 'orientation':
          matched = (media.orientation.toString()) == value;
        case 'resolution':
          final expected = parseSizeDef(FssPropertyValue(name, value))
              .getPixelSize(FssBase.fallback);
          matched = _compare(media.devicePixelRatio, operator, expected);
        case 'prefers-contrast':
          // ignore: avoid_bool_literals_in_conditional_expressions
          matched = ('more' == value) ? media.highContrast : true;
        case 'inverted-colors':
          // ignore: avoid_bool_literals_in_conditional_expressions
          matched = ('inverted' == value) ? media.invertColors : true;
        case 'prefers-color-scheme':
          // ignore: avoid_bool_literals_in_conditional_expressions
          matched = ('dark' == value)
              ? media.platformBrightness == Brightness.dark
              : true;
        default:
          matched = false;
      }
    }

    return FssSpecificity(ids: matched ? 1 : 0);
  }

  @override
  String toString() => 'FssMediaSelector: rule="$mediaQuery"';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FssMediaSelector && mediaQuery == other.mediaQuery;

  @override
  int get hashCode => mediaQuery.hashCode;

  bool _compare(double actual, String operator, double expected) =>
      switch (operator.trim()) {
        '=' => actual == expected,
        '<' => actual < expected,
        '<=' => actual <= expected,
        '>' => actual > expected,
        '>=' => actual >= expected,
        _ => actual == expected
      };
}
