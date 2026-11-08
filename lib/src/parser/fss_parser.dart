import 'package:flutter/material.dart';
import 'package:fss/src/exception/fss_parse_exception.dart';
import 'package:fss/src/parser/fss_color.dart';
import 'package:fss/src/parser/fss_media_rule.dart';
import 'package:fss/src/parser/fss_property.dart';
import 'package:fss/src/parser/fss_property_value.dart';
import 'package:fss/src/parser/fss_rule.dart';
import 'package:fss/src/parser/fss_rule_block.dart';
import 'package:fss/src/parser/fss_selector.dart';
import 'package:fss/src/parser/fss_size.dart';

/// Converts a degree value to an [Alignment] value.
Alignment convertDegreeToAlignment(double degree) {
  var result = degree;
  result %= 360; // normalize to 360 and positive degrees
  if (result < 0) {
    result = 360 - result;
  }
  final modulo = result % 45.0;
  final delta = modulo / 45.0;

  if (result >= 0 && result < 45) {
    return Alignment(delta * -1, 1.0);
  } else if (result >= 45 && result < 90) {
    return Alignment(-1.0, 1 - delta);
  } else if (result >= 90 && result < 135) {
    return Alignment(-1.0, delta * -1);
  } else if (result >= 135 && result < 180) {
    return Alignment(-1 + delta, -1.0);
  } else if (result >= 180 && result < 225) {
    return Alignment(delta, -1.0);
  } else if (result >= 225 && result < 270) {
    return Alignment(1.0, -1 + delta);
  } else if (result >= 270 && result < 315) {
    return Alignment(1.0, delta);
  } else if (result >= 315 && result < 360) {
    return Alignment(1 - delta, 1.0);
  } else {
    return Alignment.center;
  }
}

/// Parses a style sheet file into a list of rules.
///
/// Normally you would not use this method directly but access the rules
/// via a [FlutterStyleSheet] which will manage the rule resolving for you.
///
/// The input can use any layout. Both the classic multi line "pretty"
/// style and minified single line files are supported. Comments can be
/// either `// line` or `/* block */` style.
///
/// [strict] controls how recoverable problems are handled. When `true`
/// (the legacy behaviour) an [FssParseException] is thrown for unknown
/// properties, invalid declarations and unsupported selectors. When
/// `false` (the default) such declarations or whole rules are skipped
/// and a description is appended to [warnings] (if non null).
///
/// Structural errors such as unbalanced brackets are always reported
/// with an [FssParseException] carrying line and column information.
List<FssRule> parseStylesheet(
  String? input, {
  bool strict = false,
  List<String>? warnings,
}) {
  // Nothing to parse
  if (input == null || input.trim().isEmpty) {
    return [];
  }
  return _FssParser(_stripComments(input), strict, warnings).parse();
}

/// A small character based tokenizer and parser for the FSS stylesheet
/// language.
///
/// It works on the comment free input and is independent of the line
/// layout of the file. All structural characters are only considered
/// outside of string literals and at bracket depth 0.
class _FssParser {
  _FssParser(this._input, this.strict, this.warnings);

  final String _input;
  final bool strict;
  final List<String>? warnings;

  final List<FssRule> _rules = [];
  List<String>? _mediaQueries; // open @media queries (null = not inside one)
  List<FssRule>? _mediaRules; // rules collected for the open @media block

  /// Parses the whole stylesheet and returns the list of rules.
  List<FssRule> parse() {
    int pos = 0;
    while (pos < _input.length) {
      final (int idx, String? ch) = _nextStructural(pos, const ['{', '}', ';']);
      final prelude = _input.substring(pos, idx).trim();
      if (ch == null) {
        if (prelude.isNotEmpty) {
          throw FssParseException(
            'Unexpected end of stylesheet at ${_loc(idx)}, expected "{" or '
            '"}" before end of file.\nLast content: "$prelude"',
          );
        }
        break;
      }
      if (ch == ';') {
        // A top level statement without a block. Only at statements like
        // "@import url(...);" occur in real CSS and they are unsupported.
        if (prelude.isNotEmpty) {
          _recover('Skipped unsupported top level statement: "$prelude"',
              at: idx);
        }
        pos = idx + 1;
        continue;
      }
      if (ch == '}') {
        if (_mediaQueries == null) {
          throw FssParseException(
            'Unexpected "}" at ${_loc(idx)}, there is no open rule to close.',
          );
        }
        _closeMedia();
        pos = idx + 1;
        continue;
      }
      // ch == '{'
      if (prelude.isEmpty) {
        throw FssParseException(
          'Unexpected "{" at ${_loc(idx)}, expected a selector before it.',
        );
      }
      pos = _parseBlock(prelude, idx);
    }
    if (_mediaQueries != null) {
      throw FssParseException(
        'Unexpected end of stylesheet at ${_loc(_input.length)}, expected '
        '"}" to close the media block.',
      );
    }
    return _rules;
  }

  /// Handles a block starting at the "{" at position [openIdx].
  ///
  /// Returns the position just after the closing bracket of the block
  /// or just after the opening bracket in case of media blocks.
  int _parseBlock(String prelude, int openIdx) {
    if (prelude.toLowerCase().startsWith('@media')) {
      if (_mediaQueries != null) {
        throw FssParseException(
          'Nested @media blocks are not supported at ${_loc(openIdx)}',
        );
      }
      final query = prelude.substring('@media'.length).trim();
      if (query.isEmpty) {
        throw FssParseException(
          'Missing media query for "@media" at ${_loc(openIdx)}',
        );
      }
      _mediaQueries = _splitTopLevel(query, ',')
          .map((q) => q.trim())
          .where((q) => q.isNotEmpty)
          .toList();
      _mediaRules = [];
      return openIdx + 1;
    }
    if (prelude.startsWith('@')) {
      // Some other at rule like @keyframes, @font-face or @supports
      return _skipAtRuleBlock(prelude, openIdx);
    }
    // A normal rule. Parse the declarations until the closing bracket.
    final block = FssRuleBlock(const {});
    int pos = openIdx + 1;
    while (true) {
      final (int idx, String? ch) = _nextStructural(pos, const [';', '}']);
      final decl = _input.substring(pos, idx).trim();
      if (ch == null) {
        throw FssParseException(
          'Unexpected end of stylesheet at ${_loc(_input.length)}, expected '
          '"}" to close the rule "${prelude.trim()}".',
        );
      }
      if (decl.isNotEmpty) {
        _parseDeclaration(block, decl, pos);
      }
      pos = idx + 1;
      if (ch == '}') {
        break;
      }
    }
    _finishRule(prelude, openIdx, block);
    return pos;
  }

  /// Skips an unsupported at rule block like @keyframes or @font-face
  /// starting at the "{" at position [openIdx].
  ///
  /// Returns the position just after the matching closing bracket.
  int _skipAtRuleBlock(String prelude, int openIdx) {
    _recover('Skipped unsupported at rule: "${prelude.trim()}"', at: openIdx);
    int depth = 1;
    int pos = openIdx + 1;
    while (depth > 0) {
      final (int idx, String? ch) = _nextStructural(pos, const ['{', '}']);
      if (ch == null) {
        throw FssParseException(
          'Unexpected end of stylesheet at ${_loc(_input.length)}, expected '
          '"}" to close the at rule "${prelude.trim()}".',
        );
      }
      if (ch == '{') {
        depth++;
      } else {
        depth--;
      }
      pos = idx + 1;
    }
    return pos;
  }

  /// Closes the current media block and adds the collected rules.
  void _closeMedia() {
    final queries = _mediaQueries!;
    final subRules = _mediaRules!;
    _mediaQueries = null;
    _mediaRules = null;
    for (final query in queries) {
      _rules.add(FssMediaRule(query, subRules));
    }
  }

  /// Creates one rule per selector of the comma separated [prelude] and
  /// adds them to the current target rule list.
  void _finishRule(String prelude, int openIdx, FssRuleBlock block) {
    final target = _mediaRules ?? _rules;
    for (final part in _splitTopLevel(prelude, ',')) {
      final selector = part.trim();
      if (selector.isEmpty) {
        continue;
      }
      try {
        target.add(FssRule(FssSelector.parse(selector), block));
      } on FssParseException catch (e) {
        _recover('${e.message} (selector "$selector")', at: openIdx);
      }
    }
  }

  /// Parses a single `name: value` declaration and adds it to [block].
  void _parseDeclaration(FssRuleBlock block, String decl, int declStart) {
    final text = decl.trim();
    if (text.isEmpty) {
      return;
    }
    // The first ':' separates name and value. Property names do not
    // contain ':' so the first occurrence is always the right one.
    final ci = text.indexOf(':');
    if (ci < 0) {
      _recover('Invalid property definition (missing ":"): "$text"',
          at: declStart);
      return;
    }
    final name = text.substring(0, ci).trim();
    var value = text.substring(ci + 1).trim();
    // Drop a trailing "!important" flag. It is not supported but tolerated.
    if (value.toLowerCase().endsWith('!important')) {
      value = value.substring(0, value.length - '!important'.length).trim();
    }
    if (name.isEmpty || value.isEmpty) {
      _recover('Invalid property definition: "$text"', at: declStart);
      return;
    }
    parseFssRule(block, name, value, _lineOf(declStart),
        strict: strict, warnings: warnings);
  }

  /// Handles a recoverable problem.
  ///
  /// In [strict] mode an [FssParseException] is thrown. Otherwise the
  /// problem is added to [warnings] and parsing continues.
  void _recover(String message, {required int at}) {
    final full = '${_loc(at)}: $message';
    if (strict) {
      throw FssParseException(full);
    }
    warnings?.add(full);
  }

  /// Finds the next occurrence of any of the characters [chars] at
  /// bracket depth 0 and outside of string literals starting at [from].
  ///
  /// Returns the index and the character found or
  /// (input.length, null) if none is found.
  (int, String?) _nextStructural(int from, List<String> chars) {
    int depth = 0;
    int i = from;
    final n = _input.length;
    while (i < n) {
      final c = _input[i];
      if (c == '"' || c == "'") {
        i = _skipString(i);
        continue;
      }
      if (c == '(') {
        depth++;
      } else if (c == ')') {
        if (depth > 0) {
          depth--;
        }
      } else if (depth == 0 && chars.contains(c)) {
        return (i, c);
      }
      i++;
    }
    return (n, null);
  }

  /// Returns the index just after the string literal starting at [start].
  int _skipString(int start) {
    final quote = _input[start];
    int i = start + 1;
    final n = _input.length;
    while (i < n) {
      final c = _input[i];
      if (c == '\\') {
        i += 2;
        continue;
      }
      if (c == quote) {
        return i + 1;
      }
      if (c == '\n') {
        return i; // Unterminated string, recover at next line
      }
      i++;
    }
    return n;
  }

  /// Returns the 1 based line number of the character at position [idx].
  int _lineOf(int idx) {
    int line = 1;
    for (int i = 0; i < idx && i < _input.length; i++) {
      if (_input[i] == '\n') {
        line++;
      }
    }
    return line;
  }

  /// Returns a "line X, col Y" description (1 based) for [idx].
  String _loc(int idx) {
    int line = 1;
    int lineStart = 0;
    for (int i = 0; i < idx && i < _input.length; i++) {
      if (_input[i] == '\n') {
        line++;
        lineStart = i + 1;
      }
    }
    return 'line $line, col ${idx - lineStart + 1}';
  }
}

/// Removes `// line` and `/* block */` comments from [input].
///
/// Line breaks are preserved so that the line numbers of the remaining
/// text stay valid. String literals are copied unchanged and a `//`
/// that is part of a url like `http://...` is kept.
String _stripComments(String input) {
  final out = StringBuffer();
  final n = input.length;
  int i = 0;
  while (i < n) {
    final c = input[i];
    if (c == '"' || c == "'") {
      // Copy a string literal unchanged
      out.write(c);
      i++;
      while (i < n) {
        final s = input[i];
        out.write(s);
        i++;
        if (s == '\\') {
          if (i < n) {
            out.write(input[i]);
            i++;
          }
          continue;
        }
        if (s == c || s == '\n') break;
      }
      continue;
    }
    if (c == '/' && i + 1 < n) {
      final d = input[i + 1];
      if (d == '/') {
        // A `//` right after a `:` is part of a url like `http://...`
        if (i > 0 && input[i - 1] == ':') {
          out.write('//');
          i += 2;
          continue;
        }
        // A line comment goes to the end of the line
        while (i < n && input[i] != '\n') {
          i++;
        }
        continue;
      }
      if (d == '*') {
        // A block comment. Keep line breaks so line numbers stay valid.
        i += 2;
        while (
            i < n && !(input[i] == '*' && i + 1 < n && input[i + 1] == '/')) {
          if (input[i] == '\n') {
            out.write('\n');
          }
          i++;
        }
        i += 2; // Skip the `*/`
        continue;
      }
    }
    out.write(c);
    i++;
  }
  return out.toString();
}

/// Splits [text] on the [separator] character but only at bracket
/// depth 0 and outside of string literals.
List<String> _splitTopLevel(String text, String separator) {
  final parts = <String>[];
  int start = 0;
  int depth = 0;
  String? quote;
  for (int i = 0; i < text.length; i++) {
    final c = text[i];
    if (quote != null) {
      if (c == '\\') {
        i++;
        continue;
      }
      if (c == quote) {
        quote = null;
      }
      continue;
    }
    if (c == '"' || c == "'") {
      quote = c;
    } else if (c == '(') {
      depth++;
    } else if (c == ')') {
      if (depth > 0) {
        depth--;
      }
    } else if (depth == 0 && c == separator) {
      parts.add(text.substring(start, i));
      start = i + 1;
    }
  }
  parts.add(text.substring(start));
  return parts;
}

/// Parses a single property definition and adds it to the current rule block.
///
/// [strict] and [warnings] control how an unsupported property name is
/// handled. See [parseStylesheet] for the exact semantics.
void parseFssRule(
  FssRuleBlock currentRule,
  String propName,
  String? valueDef,
  int lineNo, {
  bool strict = false,
  List<String>? warnings,
}) {
  // No value then do nothing.
  if (valueDef == null || valueDef.isEmpty) {
    return;
  }
  var name = propName.toLowerCase().trim();

  // Strip a vendor prefix like "-webkit-" or "-moz-"
  final vendorMatch = RegExp(r'^-(?:webkit|moz|ms|o)-').firstMatch(name);
  if (vendorMatch != null) {
    name = name.substring(vendorMatch.end);
  }

  if (name == FssProperty.font.name) {
    parseFont(valueDef, currentRule, lineNo);
    return;
  }

  final keepCase = name.contains('-image') || name.contains('font-family');
  final value = keepCase ? valueDef.trim() : valueDef.toLowerCase().trim();

  // Check if the property is a shorthand property and parse it
  final shortHand = _shorthandParsers[name];
  if (shortHand != null) {
    shortHand(valueDef, currentRule, lineNo);
    return;
  }

  // Check if property is supported. If yes add it to the map
  final isStandardProperty = FssProperty.byName(name) != null;
  if (isStandardProperty ||
      name.startsWith(FssProperty.fssPropertyPrefix) ||
      name.startsWith(FssProperty.varPrefix)) {
    currentRule.update({name: FssPropertyValue(name, value, lineNo)});
  } else if (strict) {
    throw FssParseException(
      'Unsupported property name: "$name" at line $lineNo. Context: "$valueDef"',
    );
  } else {
    warnings?.add(
      'line $lineNo: unsupported property name: "$name". '
      'Context: "$valueDef"',
    );
  }
}

/// Parses a size definition
FssSize parseSizeDef(FssPropertyValue valueDef) =>
    FssSize.parse(valueDef.value);

/// Parses a color definition. Normally a hex color
Color parseColorDef(FssPropertyValue valueDef) {
  try {
    return FssColor.parseColor(valueDef.value);
  } on FssParseException {
    throw FssParseException.forValue(valueDef);
  }
}

/// Parses a size definition and returns the value in pixels.
double parsePercent(FssPropertyValue valueDef) {
  final def = parseSizeDef(valueDef);
  return def.unit == '%' ? def.value / 100.0 : def.value;
}

/// Parses a size definition and returns the value in pixels.
void splitShortHand(
  List<String> properties,
  String valueDef,
  FssRuleBlock currentRule,
  int lineNo,
) {
  final values = splitValues(currentRule, valueDef);
  for (int i = 0; i < values.length; i++) {
    if (i < properties.length) {
      parseFssRule(currentRule, properties[i], values[i], lineNo);
    } else {
      break;
    }
  }
}

/// Parse the 4 values for: top, right, bottom, left
void parseBoxValues(
  List<String> properties,
  String valueDef,
  FssRuleBlock currentRule,
  int lineNo,
) {
  final sideValues = splitValues(currentRule, valueDef);
  if (sideValues.length == 1) {
    parseFssRule(currentRule, properties[0], sideValues[0], lineNo);
    parseFssRule(currentRule, properties[1], sideValues[0], lineNo);
    parseFssRule(currentRule, properties[2], sideValues[0], lineNo);
    parseFssRule(currentRule, properties[3], sideValues[0], lineNo);
  } else if (sideValues.length == 2) {
    parseFssRule(currentRule, properties[0], sideValues[0], lineNo);
    parseFssRule(currentRule, properties[1], sideValues[1], lineNo);
    parseFssRule(currentRule, properties[2], sideValues[0], lineNo);
    parseFssRule(currentRule, properties[3], sideValues[1], lineNo);
  } else if (sideValues.length == 3) {
    parseFssRule(currentRule, properties[0], sideValues[0], lineNo);
    parseFssRule(currentRule, properties[1], sideValues[1], lineNo);
    parseFssRule(currentRule, properties[2], sideValues[2], lineNo);
    parseFssRule(currentRule, properties[3], sideValues[1], lineNo);
  } else if (sideValues.length >= 4) {
    parseFssRule(currentRule, properties[0], sideValues[0], lineNo);
    parseFssRule(currentRule, properties[1], sideValues[1], lineNo);
    parseFssRule(currentRule, properties[2], sideValues[2], lineNo);
    parseFssRule(currentRule, properties[3], sideValues[3], lineNo);
  }
}

/// Parse the 2 values for: top, bottom
void parseSideValues(
  List<String> properties,
  String valueDef,
  FssRuleBlock currentRule,
  int lineNo,
) {
  final values = splitValues(currentRule, valueDef);
  if (values.length > 1) {
    parseFssRule(currentRule, properties[0], values[0], lineNo);
    parseFssRule(currentRule, properties[1], values[1], lineNo);
  } else {
    parseFssRule(currentRule, properties[0], values[0], lineNo);
    parseFssRule(currentRule, properties[1], values[0], lineNo);
  }
}

/// Parses the font property and splits it into its components.
void parseFont(String valueDef, FssRuleBlock currentRule, int lineNo) {
  // we get the case insensitive string here because of the font family
  // that might use upper case.

  // TODO improve parsing of optional values
  // font: font-style font-variant font-weight font-size/line-height font-family|caption|icon|menu|message-box|small-caption|status-bar|initial|inherit;
  final values = splitValues(currentRule, valueDef);
  // TODO _resolve the parts
  if (values.length == 1) {
    parseFssRule(
      currentRule,
      FssProperty.font_family.name,
      values[0],
      lineNo,
    );
  } else if (values.length == 2) {
    parseFssRule(
      currentRule,
      FssProperty.font_size.name,
      values[0].toLowerCase(),
      lineNo,
    );
    parseFssRule(
      currentRule,
      FssProperty.font_family.name,
      values[1],
      lineNo,
    );
  } else if (values.length == 3) {
    parseFssRule(
      currentRule,
      FssProperty.font_weight.name,
      values[0].toLowerCase(),
      lineNo,
    );
    parseFssRule(
      currentRule,
      FssProperty.font_size.name,
      values[1].toLowerCase(),
      lineNo,
    );
    parseFssRule(
      currentRule,
      FssProperty.font_family.name,
      values[2],
      lineNo,
    );
  } else if (values.length >= 4) {
    parseFssRule(
      currentRule,
      FssProperty.font_style.name,
      values[0].toLowerCase(),
      lineNo,
    );
    parseFssRule(
      currentRule,
      FssProperty.font_weight.name,
      values[1].toLowerCase(),
      lineNo,
    );
    parseFssRule(
      currentRule,
      FssProperty.font_size.name,
      values[2].toLowerCase(),
      lineNo,
    );
    parseFssRule(
      currentRule,
      FssProperty.font_family.name,
      values[3],
      lineNo,
    );
  }
}

/// Splits function parameter by , supporting functions in functions.
List<String> splitFunctionParams(
  FssRuleBlock currentRule,
  String value, [
  String separator = ',',
]) {
  // remove all function bodies as they may contain ,
  final temp = value.replaceAllMapped(
    RegExp(r'\(.*?\)'),
    (m) => ''.padRight(m.end - m.start, '_'),
  );

  // Now search for , and then split the original value on these positions.
  final separatorMatcher = RegExp(separator).allMatches(temp);
  final List<String> result = [];
  int start = 0;
  for (final match in separatorMatcher) {
    result.add(
        currentRule.resolveValue(value.substring(start, match.start).trim())!);
    start = match.end;
  }
  result.add(currentRule.resolveValue(value.substring(start).trim())!);
  return result;
}

/// Splits a string with multiple values into a list
List<String> splitValues(FssRuleBlock currentRule, String value) =>
    splitFunctionParams(currentRule, value.trim(), r'\s+');

/// Darken a color by [percent] amount (100 = black)
Color darkenColor(Color c, [int percent = 10]) {
  assert(1 <= percent && percent <= 100);
  final f = 1 - percent / 100;
  return Color.from(
    alpha: c.a,
    red: c.r * f,
    green: c.g * f,
    blue: c.b * f,
  );
}

/// Lighten a color by [percent] amount (100 = white)
/*
Color lightenColor(Color c, [int percent = 10]) {
  assert(1 <= percent && percent <= 100);
  final p = percent / 100;
  return Color.fromARGB(
    c.alpha,
    c.red + ((255 - c.red) * p).round(),
    c.green + ((255 - c.green) * p).round(),
    c.blue + ((255 - c.blue) * p).round(),
  );
}
*/

/// Converts a number to a roman numeral string.
String toRoman(int number) {
  return switch (number) {
    < 1 => '',
    >= 1000 => 'M${toRoman(number - 1000)}',
    >= 900 => 'CM${toRoman(number - 900)}',
    >= 500 => 'D${toRoman(number - 500)}',
    >= 400 => 'CD${toRoman(number - 400)}',
    >= 100 => 'C${toRoman(number - 100)}',
    >= 90 => 'XC${toRoman(number - 90)}',
    >= 50 => 'L${toRoman(number - 50)}',
    >= 40 => 'XL${toRoman(number - 40)}',
    >= 10 => 'X${toRoman(number - 10)}',
    >= 9 => 'IX${toRoman(number - 9)}',
    >= 5 => 'V${toRoman(number - 5)}',
    >= 4 => 'IV${toRoman(number - 4)}',
    >= 1 => 'I${toRoman(number - 1)}',
    _ => throw FssParseException('Number input invalid: $number'),
  };
}

/// Parses a text overflow value
TextOverflow parseTextOverflow(FssPropertyValue valueDef) =>
    switch (valueDef.value) {
      'clip' => TextOverflow.clip,
      'ellipsis' => TextOverflow.ellipsis,
      'fade' => TextOverflow.fade,
      _ => throw FssParseException.forValue(valueDef)
    };

/// Parses a text align value
TextAlign parseTextAlign(FssPropertyValue valueDef) => switch (valueDef.value) {
      'left' => TextAlign.left,
      'right' => TextAlign.right,
      'center' => TextAlign.center,
      'start' => TextAlign.start,
      'end' => TextAlign.end,
      _ => throw FssParseException.forValue(valueDef)
    };

/// Parses a text align value
double parseBorderSize(FssPropertyValue? valueDef) => valueDef == null
    ? 3 // default is medium
    : switch (valueDef.value) {
        'thin' => 1,
        'medium' => 3,
        'thick' => 5,
        _ => parseSizeDef(valueDef).value
      };

/// Parses a text decoration value
TextDecorationStyle parseTextDecStyle(FssPropertyValue valueDef) =>
    switch (valueDef.value) {
      'dashed' => TextDecorationStyle.dashed,
      'dotted' => TextDecorationStyle.dotted,
      'double' => TextDecorationStyle.double,
      'solid' => TextDecorationStyle.solid,
      'wavy' => TextDecorationStyle.wavy,
      _ => throw FssParseException.forValue(valueDef)
    };

/// Parses a text decoration value
TextDecoration? parseTextDecLine(FssPropertyValue valueDef) =>
    switch (valueDef.value) {
      'none' => TextDecoration.none,
      'underline' => TextDecoration.underline,
      'line-through' => TextDecoration.lineThrough,
      'overline' => TextDecoration.overline,
      _ => throw FssParseException.forValue(valueDef)
    };

/// Parse value for vertical alignment
Alignment parseVertAlign(FssPropertyValue valueDef) => switch (valueDef.value) {
      'top' => Alignment.topCenter,
      'middle' => Alignment.center,
      'center' => Alignment.center,
      // TODO As we use a container this is not fully supported yet
      'baseline' => Alignment.center,
      'bottom' => Alignment.bottomCenter,
      _ => throw FssParseException.forValue(valueDef)
    };

/// Parses the font weight value
FontWeight? parseFontWeight(FssPropertyValue valueDef) =>
    switch (valueDef.value) {
      'normal' => FontWeight.normal,
      'bold' => FontWeight.bold,
      'bolder' => FontWeight.w800,
      'lighter' => FontWeight.w300,
      _ => FontWeight.values[((parseSizeDef(valueDef).value / 100) - 1).toInt()]
    };

/// Parses the background repeat style value
ImageRepeat parseBackgroundRepeat(FssPropertyValue valueDef) =>
    switch (valueDef.value) {
      'repeat' => ImageRepeat.repeat,
      'repeat-x' => ImageRepeat.repeatX,
      'repeat-y' => ImageRepeat.repeatY,
      _ => ImageRepeat.noRepeat
    };

//// Parses the background size style value
// TODO support 2 value mode like 100% 100% or auto 100%
BoxFit? parseBackgroundSize(FssPropertyValue valueDef) =>
    switch (valueDef.value) {
      'contain' => BoxFit.contain,
      'cover' => BoxFit.cover,
      'fill' => BoxFit.fill,
      'scale-down' => BoxFit.scaleDown,
      'fit-width' => BoxFit.fitWidth,
      'fit-height' => BoxFit.fitHeight,
      'auto' => BoxFit.none,
      _ => null
    };

/// Helper method to capitalize all words of a text.
String capitalizeAllWords(String input) {
  final result = StringBuffer();
  final words = RegExp(r'([\W-_]+)(\w+\S+)').allMatches(input);
  for (final m in words) {
    final whitespace = m.group(1)!;
    final word = m.group(2)!;
    result
      ..write(whitespace)
      ..write(word[0].toUpperCase())
      ..write(word.substring(1));
  }
  return result.toString();
}

/// Helper method to combine a horizontal and vertical alignment into a single [AlignmentGeometry].
AlignmentGeometry? combineAlignment(TextAlign? hor, Alignment? vert) {
  if (hor == null && vert == null) {
    return null;
  }
  double x = 0.0;
  final y = vert == null ? 0.0 : vert.y;
  bool directional = false;
  if (hor != null) {
    switch (hor) {
      case TextAlign.left:
        x = Alignment.centerLeft.x;
      case TextAlign.right:
        x = Alignment.centerRight.x;
      case TextAlign.start:
        directional = true;
        x = AlignmentDirectional.centerStart.start;
      case TextAlign.end:
        directional = true;
        x = AlignmentDirectional.centerEnd.start;
      case TextAlign.center:
        x = Alignment.center.x;
      case TextAlign.justify:
        x = AlignmentDirectional.centerStart.start;
    }
  }
  return directional ? AlignmentDirectional(x, y) : Alignment(x, y);
}

/// Parses an image source into an ImageProvider
ImageProvider parseImageSource(FssPropertyValue valueDef) {
  if (valueDef.value.toLowerCase().startsWith('http:') ||
      valueDef.value.toLowerCase().startsWith('https:')) {
    return NetworkImage(valueDef.value);
  }
  return AssetImage(valueDef.value);
}

/// The CSS default for the `quote` property, decoded:
/// left/right double quote and left/right single quote.
const _defaultQuotes = ['\u201c', '\u201d', '\u2018', '\u2019'];

/// Parses a content replacement value.
///
/// [quotes] is the decoded `quote` property value (a list of alternating
/// open/close quote strings). If it is null or empty the CSS default is
/// used. [nesting] is the quote nesting level (0 at the top level) and
/// selects the quote pair to use, cycling through the list.
String replaceContent(
  FssPropertyValue? contentMode,
  String input, {
  List<String>? quotes,
  int nesting = 0,
}) {
  var result = input;
  if (contentMode != null) {
    switch (contentMode.value) {
      case 'none':
        break;
      case 'normal':
        break;
      case 'open-quote':
        result = _selectQuote(quotes, nesting, close: false) ?? result;
      case 'close-quote':
        result = _selectQuote(quotes, nesting, close: true) ?? result;
      default:
        // The value is a quoted string that needs to be decoded.
        result = _decodeContentString(contentMode.value);
    }
  }
  return result;
}

/// Selects the quote string for the given nesting level.
///
/// The [quotes] list is read as pairs of open/close quotes, and the
/// nesting level cycles through the pairs. If the list has an odd number
/// of strings, the last string closes its pair as well.
///
/// Returns the CSS default quotes when [quotes] is null or empty, and
/// null for a [nesting] level below zero.
String? _selectQuote(List<String>? quotes, int nesting, {required bool close}) {
  if (nesting < 0) {
    return null;
  }
  final effective =
      (quotes == null || quotes.isEmpty) ? _defaultQuotes : quotes;
  final pairCount = (effective.length + 1) ~/ 2;
  final pairIndex = nesting % pairCount;
  final index = (pairIndex * 2 + (close ? 1 : 0)).clamp(0, effective.length - 1);
  return effective[index];
}

/// Parses a `quote` property value into a list of decoded quote strings.
///
/// The value is a list of strings, each quoted with single or double
/// quotes and possibly containing CSS escape sequences. Whitespace
/// between the strings is ignored.
List<String> parseQuotes(String value) {
  final result = <String>[];
  var i = 0;
  while (i < value.length) {
    final c = value[i];
    if (c != '"' && c != '\'') {
      i++;
      continue;
    }
    // Scan to the matching closing quote, skipping escaped characters.
    var j = i + 1;
    var closed = false;
    while (j < value.length) {
      if (value[j] == '\\' && j + 1 < value.length) {
        j += 2;
        continue;
      }
      if (value[j] == c) {
        closed = true;
        break;
      }
      j++;
    }
    if (!closed) {
      break;
    }
    result.add(_decodeContentString(value.substring(i, j + 1)));
    i = j + 1;
  }
  return result;
}

/// Decode a content string value: strip the surrounding quotes and decode
/// CSS escape sequences.
///
/// A string like `"Say \"hi\""` decodes to `Say "hi"`.
String _decodeContentString(String value) {
  // Only decode if it is a quoted string.
  if (value.length < 2) {
    return value;
  }
  final first = value[0];
  final last = value[value.length - 1];
  final isQuoted = (first == '"' || first == "'") && first == last;
  if (!isQuoted) {
    return value;
  }
  final body = value.substring(1, value.length - 1);
  final result = StringBuffer();
  var i = 0;
  while (i < body.length) {
    final c = body[i];
    if (c == '\\' && i + 1 < body.length) {
      final next = body[i + 1];
      // Hex escape: \[0-9a-fA-F]{1,6}, optionally followed by a space.
      if (RegExp(r'[0-9a-fA-F]').hasMatch(next)) {
        var hex = '';
        var j = i + 1;
        while (j < body.length &&
            hex.length < 6 &&
            RegExp(r'[0-9a-fA-F]').hasMatch(body[j])) {
          hex += body[j];
          j++;
        }
        // A space directly after a hex escape is part of the escape.
        if (j < body.length && (body[j] == ' ' || body[j] == '\n')) {
          j++;
        }
        result.write(String.fromCharCode(int.parse(hex, radix: 16)));
        i = j;
      } else {
        // Simple escape like \n, \t, \" or \\\\ — keep the character.
        result.write(next);
        i += 2;
      }
    } else {
      result.write(c);
      i++;
    }
  }
  return result.toString();
}

/// Parses a gradient direction value.
/// The value is a string like "top", "right", "bottom left" etc.
double parseGradientTo(String dir) => switch (dir) {
      'top' => 0.0,
      'right top' => 45.0,
      'right' => 90.0,
      'bottom right' => 135.0,
      'bottom' => 180.0,
      'bottom left' => 225.0,
      'left' => 270.0,
      'left top' => 315.0,
      _ => 0.0
    };

/// Parses a text transform value.
/// The value is a string like "capitalize", "uppercase", "lowercase" etc.
String applyTextTransform(FssPropertyValue? textTransform, String input) =>
    textTransform == null
        ? input
        : switch (textTransform.value) {
            'lowercase' => input.toLowerCase(),
            'uppercase' => input.toUpperCase(),
            'capitalize' => capitalizeAllWords(input),
            _ => input
          };

/// Parses a list style type value.
/// The value is a string like "disc", "circle", "square" etc.
String parseListStyleSymbol(String? value, int position, int max) {
  switch (value) {
    // What a shame but the Noto font does not contain these characters!
    case 'disc':
    //  return '\u{2022}';
    case 'circle':
    //  return '\u{2E30}';
    case 'square':
      //  return 'square'; // '\u{2043}'
      break;

    case 'decimal':
      return '$position.';
    case 'decimal-leading-zero':
      return '${position.toString().padLeft('$max'.length, '0')}.';
    case 'lower-alpha':
    case 'lower-latin':
      // Fix this: Does not work nicely if z is reached
      final char = 'a'.codeUnitAt(0) + position - 1;
      return '${String.fromCharCode(char)}.';
    case 'upper-alpha':
    case 'upper-latin':
      // Fix this: Does not work nicely if z is reached
      final char = 'A'.codeUnitAt(0) + position - 1;
      return '${String.fromCharCode(char)}.';
    case 'lower-greek':
      // Fix this: Does not work nicely if z is reached
      final char = 'α'.codeUnitAt(0) + position - 1;
      return '${String.fromCharCode(char)}.';
    case 'lower-roman':
      return '${toRoman(position).toLowerCase()}.';
    case 'upper-roman':
      return '${toRoman(position)}.';
  }
  // A custom string
  return value!;
}

/// Map of shorthand properties to their parsing functions
final _shorthandParsers = {
  FssProperty.padding.name: (String v, FssRuleBlock r, int l) =>
      parseBoxValues([
        FssProperty.padding_top.name,
        FssProperty.padding_right.name,
        FssProperty.padding_bottom.name,
        FssProperty.padding_left.name
      ], v, r, l),
  FssProperty.margin.name: (String v, FssRuleBlock r, int l) => parseBoxValues([
        FssProperty.margin_top.name,
        FssProperty.margin_right.name,
        FssProperty.margin_bottom.name,
        FssProperty.margin_left.name
      ], v, r, l),
  FssProperty.margin_block.name: (String v, FssRuleBlock r, int l) =>
      parseSideValues([
        FssProperty.margin_top.name,
        FssProperty.margin_bottom.name,
      ], v, r, l),
  FssProperty.margin_block_start.name: (String v, FssRuleBlock r, int l) =>
      splitShortHand([FssProperty.margin_top.name], v, r, l),
  FssProperty.margin_block_end.name: (String v, FssRuleBlock r, int l) =>
      splitShortHand([FssProperty.margin_bottom.name], v, r, l),
  FssProperty.margin_inline.name: (String v, FssRuleBlock r, int l) =>
      parseSideValues([
        FssProperty.margin_left.name,
        FssProperty.margin_right.name,
      ], v, r, l),
  FssProperty.margin_inline_start.name: (String v, FssRuleBlock r, int l) =>
      splitShortHand([FssProperty.margin_left.name], v, r, l),
  FssProperty.margin_inline_end.name: (String v, FssRuleBlock r, int l) =>
      splitShortHand([FssProperty.margin_right.name], v, r, l),
  FssProperty.border.name: (String v, FssRuleBlock r, int l) => splitShortHand([
        FssProperty.border_width.name,
        FssProperty.border_style.name,
        FssProperty.border_color.name,
      ], v, r, l),
  FssProperty.border_top.name: (String v, FssRuleBlock r, int l) =>
      splitShortHand([
        FssProperty.border_top_width.name,
        FssProperty.border_top_style.name,
        FssProperty.border_top_color.name,
      ], v, r, l),
  FssProperty.border_bottom.name: (String v, FssRuleBlock r, int l) =>
      splitShortHand([
        FssProperty.border_bottom_width.name,
        FssProperty.border_bottom_style.name,
        FssProperty.border_bottom_color.name,
      ], v, r, l),
  FssProperty.border_left.name: (String v, FssRuleBlock r, int l) =>
      splitShortHand([
        FssProperty.border_left_width.name,
        FssProperty.border_left_style.name,
        FssProperty.border_left_color.name,
      ], v, r, l),
  FssProperty.border_right.name: (String v, FssRuleBlock r, int l) =>
      splitShortHand([
        FssProperty.border_right_width.name,
        FssProperty.border_right_style.name,
        FssProperty.border_right_color.name,
      ], v, r, l),
  FssProperty.border_width.name: (String v, FssRuleBlock r, int l) =>
      parseBoxValues([
        FssProperty.border_top_width.name,
        FssProperty.border_right_width.name,
        FssProperty.border_bottom_width.name,
        FssProperty.border_left_width.name,
      ], v, r, l),
  FssProperty.border_color.name: (String v, FssRuleBlock r, int l) =>
      parseBoxValues([
        FssProperty.border_top_color.name,
        FssProperty.border_right_color.name,
        FssProperty.border_bottom_color.name,
        FssProperty.border_left_color.name,
      ], v, r, l),
  FssProperty.border_style.name: (String v, FssRuleBlock r, int l) =>
      parseBoxValues([
        FssProperty.border_top_style.name,
        FssProperty.border_right_style.name,
        FssProperty.border_bottom_style.name,
        FssProperty.border_left_style.name,
      ], v, r, l),
  FssProperty.border_radius.name: (String v, FssRuleBlock r, int l) =>
      parseBoxValues([
        FssProperty.border_top_left_radius.name,
        FssProperty.border_top_right_radius.name,
        FssProperty.border_bottom_right_radius.name,
        FssProperty.border_bottom_left_radius.name,
      ], v, r, l),
  FssProperty.text_stroke.name: (String v, FssRuleBlock r, int l) =>
      splitShortHand([
        FssProperty.text_stroke_width.name,
        FssProperty.text_stroke_color.name,
      ], v, r, l),
  FssProperty.text_decoration.name: (String v, FssRuleBlock r, int l) =>
      splitShortHand([
        FssProperty.text_decoration_line.name,
        FssProperty.text_decoration_style.name,
        FssProperty.text_decoration_color.name,
      ], v, r, l),
};
