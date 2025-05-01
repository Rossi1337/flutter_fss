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
List<FssRule> parseStylesheet(String? input) {
  // Nothing to parse
  if (input == null || input.trim().isEmpty) {
    return [];
  }

  final List<FssRule> result = [];
  FssRuleBlock? currentBlock;
  List<String> selectorPathList = [];
  String partialSelector = '';
  List<String> mediaRulesList = [];
  List<FssRule> collectList = result;
  bool inBlockComment = false;

  final lines = input.split(RegExp(r'[\r\n]+'));
  int lineNo = -1;
  for (var line in lines) {
    lineNo++;
    if (line.contains('/*')) {
      inBlockComment = !line.contains('*/');
      line = line.substring(0, line.indexOf('/*'));
    }
    if (inBlockComment && line.contains('*/')) {
      line = line.substring(line.indexOf('*/') + 2);
      inBlockComment = false;
    }
    line = line.trim();

    // Skip empty lines and // commented lines
    if (line.isEmpty || line.startsWith('//') || inBlockComment) continue;

    // The first line that we find defines the path of the style
    // Can have a bracket on the end of the line or not.
    // Example field.myfield highlight {
    if (currentBlock == null) {
      // media query blocks
      if (line.toLowerCase().startsWith('@media')) {
        final mediaQuery = line.indexOf('{') > 0
            ? line.substring(0, line.indexOf('{')).trim()
            : line;
        mediaRulesList = mediaQuery.split(',');
        collectList = [];
        continue;
      }
      if (line == '{') continue;
      if (line == '}') {
        final List<FssRule> subRules = [];
        collectList.forEach(subRules.add);
        for (final mq in mediaRulesList) {
          result.add(FssMediaRule(mq, subRules));
        }
        collectList = result;
      }
      // media query end

      // Start of a rule

      // Selector on multiple lines?
      if (line.endsWith(',')) {
        partialSelector += line;
        continue;
      }

      var selectorPath = line.indexOf('{') > 0
          ? line.substring(0, line.indexOf('{')).trim()
          : line;
      if (partialSelector.isNotEmpty) {
        // combine the partial selector with the current selector
        selectorPath = partialSelector + selectorPath;
        partialSelector = '';
      }
      selectorPathList = selectorPath.split(',');

      currentBlock = FssRuleBlock(const {});
    } // So we are inside of a style definition.
    else {
      // Bracket on next line and not at the end of a style path
      if (line == '{') continue;
      // End Bracket so close style
      if (line == '}') {
        for (final path in selectorPathList) {
          final FssSelector selector = FssSelector.parse(path);
          collectList.add(FssRule(selector, currentBlock));
        }
        currentBlock = null;
        continue;
      }
      final nameValue = line.split(':');
      if (nameValue.length < 2) {
        throw FssParseException(
            'Invalid property definition at line $lineNo: "$line"');
      }
      final name = nameValue[0].trim();
      var valueDef = nameValue[1].trim();
      // Cut the ending ;
      valueDef = valueDef.endsWith(';')
          ? valueDef.substring(0, valueDef.length - 1)
          : valueDef;

      parseFssRule(currentBlock, name, valueDef, lineNo);
    }
  }
  return result;
}

/// Parses a single property definition and adds it to the current rule block.
void parseFssRule(
  FssRuleBlock currentRule,
  String propName,
  String? valueDef,
  int lineNo,
) {
  // No value then do nothing.
  if (valueDef == null) {
    return;
  }
  final name = propName.toLowerCase().trim();

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
  } else {
    throw FssParseException(
      'Unsupported property name: "$name" at line $lineNo. Context: "$valueDef"',
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

/// Parses a content replacement value.
String replaceContent(FssPropertyValue? contentMode, String input) {
  var result = input;
  if (contentMode != null) {
    switch (contentMode.value) {
      case 'none':
        break;
      case 'normal':
        break;
      case 'open-quote':
        // TODO get this from "quote"
        result = '"';
      case 'close-quote':
        // TODO get this from "quote"
        result = '"';
      default:
        // TODO content "string" needs to be decoded properly
        result = contentMode.value;
    }
  }
  return result;
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
