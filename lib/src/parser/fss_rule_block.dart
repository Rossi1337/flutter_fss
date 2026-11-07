import 'package:flutter/material.dart';
import 'package:fss/src/border/fss_dashed_border.dart';
import 'package:fss/src/exception/fss_parse_exception.dart';
import 'package:fss/src/parser/fss_angle.dart';
import 'package:fss/src/parser/fss_base.dart';
import 'package:fss/src/parser/fss_parser.dart';
import 'package:fss/src/parser/fss_property.dart';
import 'package:fss/src/parser/fss_property_value.dart';
import 'package:fss/src/parser/fss_size.dart';

/// A list of properties representing all properties of a rule block.
///
/// This will be used for parsing a rule but also to merge and inherit
/// properties into an "applicable rule block" when resolving all rules for a
/// given element.
@immutable
class FssRuleBlock {
  /// Constructs a rule from the given properties.
  FssRuleBlock(
    Map<String, FssPropertyValue>? properties, {
    FssRuleBlock? parent,
    FssRuleBlock? initialValues,
  })  : _parent = parent,
        _initialValues = initialValues {
    if (properties != null) {
      _properties.addAll(properties);
    }
  }

  final Map<String, FssPropertyValue> _properties = {};
  final FssRuleBlock? _initialValues;
  final FssRuleBlock? _parent;

  Color? get color => getColor(FssProperty.color.name);

  Color? get backgroundColor => getColor(FssProperty.background_color.name);

  DecorationImage? get backgroundImage {
    final imagePath = get(FssProperty.background_image.name);
    // TODO support multiple images and merge them into a DecorationImage.
    // Maybe support effects via BackdropFilter widget
    if (imagePath == null) {
      return null;
    }
    if (imagePath.value.contains('linear-gradient(') ||
        imagePath.value.contains('radial-gradient(')) {
      return null;
    }

    final img = parseImageSource(imagePath);

    var propValue = get(FssProperty.background_repeat.name);
    final repeat = propValue == null
        ? ImageRepeat.repeat
        : parseBackgroundRepeat(propValue);

    propValue = get(FssProperty.background_size.name);
    final BoxFit? boxFit =
        propValue == null ? null : parseBackgroundSize(propValue);

    propValue = get(FssProperty.background_position.name);
    AlignmentGeometry align = Alignment.topLeft;
    if (propValue != null) {
      final parts = splitValues(this, propValue.value);
      final hor = parseTextAlign(FssPropertyValue('', parts[0]));
      final vert = parts.length > 1
          ? parseVertAlign(FssPropertyValue('', parts[1]))
          : null;
      align = combineAlignment(hor, vert) ?? Alignment.center;
    }

    return DecorationImage(
      image: img,
      //colorFilter: ColorFilter.mode(Colors.white, BlendMode.darken)
      repeat: repeat,
      fit: boxFit,
      alignment: align,
    );
  }

  Gradient? get backgroundGradient {
    final imageDef = get(FssProperty.background_image.name);
    if (imageDef == null) {
      return null;
    }
    final propValue = imageDef.value;
    if (propValue.startsWith('linear-gradient(')) {
      return _parseLinearGradient(propValue, imageDef);
    } else if (propValue.startsWith('radial-gradient(')) {
      return _parseRadialGradient(propValue, imageDef);
    } else if (propValue.startsWith('sweep-gradient(')) {
      //TODO support cone gradient?.
      return const SweepGradient(
        colors: [Colors.black, Colors.white],
        startAngle: -4.45,
        endAngle: 4.7,
      );
    }
    return null;
  }

  BoxBorder? get border {
    final topSide = getBorderSide('top');
    final bottomSide = getBorderSide('bottom');
    final leftSide = getBorderSide('left');
    final rightSide = getBorderSide('right');

    // No border or hidden border
    if (BorderStyle.none == topSide.style &&
        BorderStyle.none == bottomSide.style &&
        BorderStyle.none == leftSide.style &&
        BorderStyle.none == rightSide.style) {
      return null;
    }

    final topStyle = getString('border-top-style');
    final bottomStyle = getString('border-bottom-style');
    final leftStyle = getString('border-left-style');
    final rightStyle = getString('border-right-style');

    // These are all painted via the standard border
    final simple = {'solid', 'none', 'hidden', 'inset', 'outset', null};
    final onlySolid = simple.contains(topStyle) &&
        simple.contains(bottomStyle) &&
        simple.contains(leftStyle) &&
        simple.contains(rightStyle);

    if (onlySolid) {
      return Border(
        top: topSide,
        bottom: bottomSide,
        left: leftSide,
        right: rightSide,
      );
    }

    // With different sides or non solid stroke.
    return DashPathBorder(
      top: topSide,
      dashTopArray: _parseBorderPattern(topSide, topStyle),
      bottom: bottomSide,
      dashBottomArray: _parseBorderPattern(bottomSide, bottomStyle),
      left: leftSide,
      dashLeftArray: _parseBorderPattern(leftSide, leftStyle),
      right: rightSide,
      dashRightArray: _parseBorderPattern(rightSide, rightStyle),
    );
  }

  BorderRadiusGeometry? get borderRadius {
    final tl = getSize(FssProperty.border_top_left_radius.name);
    final tr = getSize(FssProperty.border_top_right_radius.name);
    final br = getSize(FssProperty.border_bottom_right_radius.name);
    final bl = getSize(FssProperty.border_bottom_left_radius.name);
    if (tl == null && tr == null && bl == null && br == null) {
      return null;
    }
    // TODO support elliptical  corners too?

    return BorderRadius.only(
      topLeft: tl == null ? Radius.zero : Radius.circular(tl),
      topRight: tr == null ? Radius.zero : Radius.circular(tr),
      bottomLeft: bl == null ? Radius.zero : Radius.circular(bl),
      bottomRight: br == null ? Radius.zero : Radius.circular(br),
    );
  }

  String get display => getString(FssProperty.display.name) ?? 'inline';

  TextStyle? get textStyle {
    Color? color = getColor(FssProperty.color.name);

    FssPropertyValue? propValue;

    final sfValue = getString(FssProperty.font_style.name);
    final fontStyle = (sfValue == null)
        ? null
        : ((sfValue == 'italic') ? FontStyle.italic : FontStyle.normal);

    var fontFamily = getString(FssProperty.font_family.name);
    List<String>? fallbackFonts;
    if (fontFamily != null) {
      final fontFaces = splitFunctionParams(this, fontFamily);
      final fonts = fontFaces
          .map((e) => e.trim())
          .map((e) => e.startsWith('"') ? e.substring(1) : e)
          .map((e) => e.endsWith('"') ? e.substring(0, e.length - 1) : e)
          .map((e) => resolveValue(e)!)
          .toList();
      fontFamily = fonts[0];
      fallbackFonts = fonts.length > 1 ? fonts.sublist(1) : null;
    }

    final fontSize = getSize(FssProperty.font_size.name);

    propValue = get(FssProperty.font_weight.name);
    final fontWeight = (propValue == null) ? null : parseFontWeight(propValue);

    propValue = get(FssProperty.text_decoration_line.name);
    final decoration =
        (propValue == null) ? TextDecoration.none : parseTextDecLine(propValue);

    propValue = get(FssProperty.text_decoration_style.name);
    final decorationStyle = (decoration == null || propValue == null)
        ? null
        : parseTextDecStyle(propValue);

    final decorationColor = decoration == null
        ? null
        : getColor(FssProperty.text_decoration_color.name);

    final decorationThickness = decoration == null
        ? null
        : getSize(FssProperty.text_decoration_thickness.name);

    propValue = get(FssProperty.text_shadow.name);
    final shadows =
        (propValue == null) ? null : [_parseShadow(propValue, _getBaseline())];

    Paint? outline;
    final strokeWidth = getSize(FssProperty.text_stroke_width.name);
    final strokeCol = getColor(FssProperty.text_stroke_color.name);
    if (strokeWidth != null && strokeCol != null) {
      outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = strokeCol;
      // TODO setting an outline will override the text color
      // https://github.com/flutter/flutter/issues/29911
      color = null;
    }

    final letterSpacing = getSize(FssProperty.letter_spacing.name);
    final wordSpacing = getSize(FssProperty.word_spacing.name);
    final height = getSize(FssProperty.height.name);

    return TextStyle(
      color: color,
      fontStyle: fontStyle,
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamilyFallback: fallbackFonts,
      decoration: decoration,
      decorationStyle: decorationStyle,
      decorationColor: decorationColor,
      decorationThickness: decorationThickness,
      shadows: shadows,
      foreground: outline,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
    );
  }

  TextAlign? get textAlign {
    final value = get(FssProperty.text_align.name);
    return value == null ? null : parseTextAlign(value);
  }

  Alignment? get verticalAlign {
    final propValue = get(FssProperty.vertical_align.name);
    return propValue == null ? null : parseVertAlign(propValue);
  }

  AlignmentGeometry? get alignment =>
      combineAlignment(textAlign, verticalAlign);

  BoxShadow? get boxShadow {
    final value = get(FssProperty.box_shadow.name);
    return value == null ? null : _parseBoxShadow(value, _getBaseline());
  }

  bool get visible {
    final value = get(FssProperty.visibility.name);
    return value == null || value.value != 'hidden';
  }

  bool get contentVisible {
    final value = get(FssProperty.content_visibility.name);
    return value == null || value.value != 'hidden';
  }

  TextOverflow? get textOverflow {
    final value = get(FssProperty.text_overflow.name);
    return value == null ? null : parseTextOverflow(value);
  }

  String? get whiteSpace => getString(FssProperty.white_space.name);

  /// Should we wrap text or render it in a single line?
  /// This is determined by looking at the white-space property
  bool get wrapText => 'nowrap' != whiteSpace;

  TextDirection? get direction {
    final value = get(FssProperty.direction.name);
    return value == null
        ? null
        : value.value == 'rtl'
            ? TextDirection.rtl
            : TextDirection.ltr;
  }

  double? get lineHeight => getSize(FssProperty.line_height.name);

  double? get maxHeight => getSize(FssProperty.max_height.name);
  double? get minHeight => getSize(FssProperty.min_height.name);
  double? get maxWidth => getSize(FssProperty.max_width.name);
  double? get minWidth => getSize(FssProperty.min_width.name);

  BoxConstraints? get constraints => maxHeight == null &&
          minHeight == null &&
          maxWidth == null &&
          minWidth == null
      ? null
      : BoxConstraints(
          maxHeight: maxHeight ?? 0.0,
          minHeight: minHeight ?? 0.0,
          maxWidth: maxWidth ?? 0.0,
          minWidth: minWidth ?? 0.0,
        );

  double? get width => getSize(FssProperty.width.name);
  double? get height => getSize(FssProperty.height.name);

  EdgeInsetsGeometry? get margin {
    final top = getSize(FssProperty.margin_top.name);
    final left = getSize(FssProperty.margin_left.name);
    final bottom = getSize(FssProperty.margin_bottom.name);
    final right = getSize(FssProperty.margin_right.name);
    return top == null && left == null && bottom == null && right == null
        ? null
        : EdgeInsets.only(
            top: top ?? 0.0,
            left: left ?? 0.0,
            bottom: bottom ?? 0.0,
            right: right ?? 0.0,
          );
  }

  EdgeInsetsGeometry? get padding {
    final top = getSize(FssProperty.padding_top.name);
    final left = getSize(FssProperty.padding_left.name);
    final bottom = getSize(FssProperty.padding_bottom.name);
    final right = getSize(FssProperty.padding_right.name);
    return top == null && left == null && bottom == null && right == null
        ? null
        : EdgeInsets.only(
            top: top ?? 0.0,
            left: left ?? 0.0,
            bottom: bottom ?? 0.0,
            right: right ?? 0.0,
          );
  }

  Matrix4? get transformMatrix {
    final transDef = getString(FssProperty.transform.name);
    if (transDef == null || transDef == 'none') {
      return null;
    }
    final Matrix4 result = Matrix4.identity();
    for (final trans in splitValues(this, transDef)) {
      final functionSpec =
          trans.substring(trans.indexOf('(') + 1, trans.indexOf(')')).trim();
      if (trans.startsWith('rotate(') || trans.startsWith('rotatez(')) {
        result.multiply(
          Matrix4.rotationZ(FssAngle.parse(functionSpec).getRadians()),
        );
      }
      if (trans.startsWith('rotatex(')) {
        result.multiply(
          Matrix4.rotationX(FssAngle.parse(functionSpec).getRadians()),
        );
      }
      if (trans.startsWith('rotatey(')) {
        result.multiply(
          Matrix4.rotationY(FssAngle.parse(functionSpec).getRadians()),
        );
      }
      if (trans.startsWith('scale(')) {
        final params = splitFunctionParams(this, functionSpec);
        result.multiply(
          Matrix4.diagonal3Values(
            FssSize.parse(params[0]).getPixelSize(_getBaseline()),
            params.length > 1
                ? FssSize.parse(params[1]).getPixelSize(_getBaseline())
                : 1.0,
            params.length > 2
                ? FssSize.parse(params[2]).getPixelSize(_getBaseline())
                : 1.0,
          ),
        );
      }

      if (trans.startsWith('scalex(')) {
        final value = FssSize.parse(functionSpec).getPixelSize(_getBaseline());
        result.multiply(Matrix4.diagonal3Values(value, 1.0, 1.0));
      }
      if (trans.startsWith('scaley(')) {
        final value = FssSize.parse(functionSpec).getPixelSize(_getBaseline());
        result.multiply(Matrix4.diagonal3Values(1.0, value, 1.0));
      }
      if (trans.startsWith('scalez(')) {
        final value = FssSize.parse(functionSpec).getPixelSize(_getBaseline());
        result.multiply(Matrix4.diagonal3Values(1.0, 1.0, value));
      }
      if (trans.startsWith('skew(')) {
        final params = splitFunctionParams(this, functionSpec);
        result.multiply(
          Matrix4.skew(
            FssAngle.parse(params[0]).getRadians(),
            params.length > 1 ? FssAngle.parse(params[1]).getRadians() : 0,
          ),
        );
      }
      if (trans.startsWith('skewx(')) {
        final value = FssAngle.parse(functionSpec).getRadians();
        result.multiply(Matrix4.skewX(value));
      }
      if (trans.startsWith('skewy(')) {
        final value = FssAngle.parse(functionSpec).getRadians();
        result.multiply(Matrix4.skewY(value));
      }
      if (trans.startsWith('translate(')) {
        final params = splitFunctionParams(this, functionSpec);
        result.multiply(
          Matrix4.translationValues(
            FssSize.parse(params[0]).getPixelSize(_getBaseline()),
            params.length > 1
                ? FssSize.parse(params[1]).getPixelSize(_getBaseline())
                : 0,
            params.length > 2
                ? FssSize.parse(params[2]).getPixelSize(_getBaseline())
                : 0,
          ),
        );
      }
      if (trans.startsWith('translatex(')) {
        final value = FssSize.parse(functionSpec).getPixelSize(_getBaseline());
        result.multiply(Matrix4.translationValues(value, 0, 0));
      }
      if (trans.startsWith('translatey(')) {
        final value = FssSize.parse(functionSpec).getPixelSize(_getBaseline());
        result.multiply(Matrix4.translationValues(0, value, 0));
      }
      if (trans.startsWith('translatez(')) {
        final value = FssSize.parse(functionSpec).getPixelSize(_getBaseline());
        result.multiply(Matrix4.translationValues(0, 0, value));
      }
    }

    return result == Matrix4.identity() ? null : result;
  }

  ImageProvider? getListStyleImage() {
    final imagePath = get(FssProperty.list_style_image.name);
    return imagePath == null ? null : parseImageSource(imagePath);
  }

  String getListStyleSymbol(int position, int max) {
    var value = getString(FssProperty.list_style_type.name);
    value ??= FssProperty.list_style_type.initialValue;
    return parseListStyleSymbol(value, position, max);
  }

  /// Merges this rule with another one.
  /// All properties that are not null are taken over.
  FssRuleBlock merge(FssRuleBlock? other) {
    final result = FssRuleBlock(
      const {},
      parent: _parent,
      initialValues: _initialValues,
    );
    result._properties.addAll(_properties);
    if (other != null) {
      result._properties.addAll(other._properties);
    }
    return result;
  }

  /// Transforms and replaces text content
  /// This applies the "text_transformation" and "content" to the input text
  String transformText(String input) {
    var result = input;
    result = _replaceContent(result);
    result = _applyTextTransform(result);
    return result;
  }

  FssPropertyValue? get(String prop) {
    var lookup = _properties[prop];

    final propDef = FssProperty.byName(prop);
    final bool inheritingProperty = propDef != null && propDef.inherited;

    // Handle special value 'unset'
    if (lookup != null && lookup.value == 'unset') {
      return inheritingProperty
          ? _parent?.get(lookup.name)
          : _initialValues?.get(lookup.name);
    }

    // Handle special value 'initial'
    if (lookup != null && lookup.value == 'initial' && _initialValues != null) {
      return _initialValues!.get(prop);
    }

    // Handle special value 'inherit'
    if (lookup != null && lookup.value == 'inherit') {
      if (!inheritingProperty) {
        throw FssParseException('Cannot inherit $prop ');
      }
      return _parent?.get(prop);
    }

    // Not found and property allows to inherit from parent
    if (lookup == null && inheritingProperty && _parent != null) {
      lookup = _parent!.get(prop);
    }
    if (lookup == null && _initialValues != null) {
      lookup = _initialValues!.get(prop);
    }
    return _resolve(lookup);
  }

  String? getString(String prop) => get(prop)?.value;

  double? getSize(String prop) {
    final propValue = get(prop);
    return propValue == null
        ? null
        : parseSizeDef(propValue).getPixelSize(_getBaseline());
  }

  Color? getColor(String prop) {
    var propValue = get(prop);
    if (propValue != null && propValue.value == 'currentcolor') {
      propValue = get(FssProperty.color.name);
    }
    return propValue == null ? null : parseColorDef(propValue);
  }

  @override
  String toString() {
    final sb = StringBuffer('FssRuleBlock {\n');
    _properties.forEach((key, prop) => sb.writeln('  $key: ${prop.value};'));
    sb.writeln('}');
    return sb.toString();
  }

  BorderSide getBorderSide(String side) {
    final colProp = getColor('border-$side-color');
    var borderColor =
        colProp ?? getColor(FssProperty.color.name) ?? Colors.black;

    final widthProp = get('border-$side-width');
    final borderWidth = parseBorderSize(widthProp);

    final styleProp = get('border-$side-style');
    if (colProp == null && widthProp == null && styleProp == null) {
      return BorderSide.none;
    }

    BorderStyle style = BorderStyle.solid;
    if (styleProp == null ||
        'none' == styleProp.value ||
        'hidden' == styleProp.value) {
      style = BorderStyle.none;
    }

    if ('inset' == styleProp?.value && (side == 'top' || side == 'left')) {
      borderColor = darkenColor(borderColor, 30);
    }
    if ('outset' == styleProp?.value && (side == 'bottom' || side == 'right')) {
      borderColor = darkenColor(borderColor, 30);
    }

    return BorderSide(color: borderColor, width: borderWidth, style: style);
  }

  double convert(String sizeDef) =>
      parseSizeDef(FssPropertyValue('', sizeDef)).getPixelSize(_getBaseline());

  void update(Map<String, FssPropertyValue> properties) {
    // TODO implement a merge mode?
    _properties.addAll(properties);
  }

  FssBase _getBaseline() {
    final emBase = _parent?.getSize(FssProperty.font_size.name);
    final remBase = _initialValues?.getSize(FssProperty.font_size.name);

    // Screen size is stored in internal properties
    final screenWidth = FssSize.parse(
      get(FssProperty.fss_screen_width.name)?.value ??
          FssProperty.fss_screen_width.initialValue!,
    ).value;
    final screenHeight = FssSize.parse(
      get(FssProperty.fss_screen_height.name)?.value ??
          FssProperty.fss_screen_height.initialValue!,
    ).value;

    return FssBase(
      remBase: remBase,
      emBase: emBase,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
  }

  // Resolves the value of a given property by replacing variables and
  // resolving special property values.
  FssPropertyValue? _resolve(FssPropertyValue? propertyValue) {
    if (propertyValue == null) {
      return null;
    }
    // Handle special value 'none'
    if (propertyValue.value == 'none') {
      return null;
    }

    if (!propertyValue.value.startsWith('var(')) {
      return propertyValue;
    }
    // Try to resolve var.
    final varName = propertyValue.value
        .substring(4, propertyValue.value.lastIndexOf(')'))
        .trim();
    final replacement = get(varName);
    if (replacement == null) {
      return null;
    }

    return _resolve(replacement);
  }

  // Resolves the value by replacing variables and
  // resolving special property values.
  String? resolveValue(String? value) {
    if (value == null) {
      return null;
    }
    // Handle special value 'none'
    if (value == 'none') {
      return null;
    }

    if (!value.startsWith('var(')) {
      return value;
    }
    // Try to resolve var.
    final varName = value.substring(4, value.lastIndexOf(')')).trim();
    final replacement = get(varName);
    if (replacement == null) {
      return null;
    }

    return resolveValue(replacement.value);
  }

  Shadow _parseShadow(FssPropertyValue valueDef, FssBase base) {
    // text-shadow: .2em .2em 0.3em #ccc;
    final values = splitValues(this, valueDef.value);
    final dx = parseSizeDef(valueDef.subValue(values[0])).getPixelSize(base);
    final dy = values.length > 1
        ? parseSizeDef(valueDef.subValue(values[1])).getPixelSize(base)
        : 0.0;
    final blur = values.length > 2
        ? parseSizeDef(valueDef.subValue(values[2])).getPixelSize(base)
        : 0.0;
    final color = values.length > 3
        ? parseColorDef(valueDef.subValue(values[3]))
        : Colors.black;
    return Shadow(offset: Offset(dx, dy), color: color, blurRadius: blur);
  }

  BoxShadow _parseBoxShadow(FssPropertyValue valueDef, FssBase base) {
    // text-shadow: .2em .2em 0.3em #ccc;
    final values = splitValues(this, valueDef.value);
    final dx = parseSizeDef(valueDef.subValue(values[0])).getPixelSize(base);
    final dy = values.length > 1
        ? parseSizeDef(valueDef.subValue(values[1])).getPixelSize(base)
        : 0.0;
    final blur = values.length > 2
        ? parseSizeDef(valueDef.subValue(values[2])).getPixelSize(base)
        : 0.0;
    final spread = values.length > 3
        ? parseSizeDef(valueDef.subValue(values[3])).getPixelSize(base)
        : 0.0;
    final color = values.length > 4
        ? parseColorDef(valueDef.subValue(values[4]))
        : Colors.black;
    return BoxShadow(
      offset: Offset(dx, dy),
      blurRadius: blur,
      spreadRadius: spread,
      color: color,
    );
  }

  LinearGradient _parseLinearGradient(
    String propValue,
    FssPropertyValue imageDef,
  ) {
    final spec = propValue.substring(
      propValue.indexOf('(') + 1,
      propValue.lastIndexOf(')'),
    );
    final parts = splitFunctionParams(this, spec);

    final List<Color> colors = [];
    final List<double> stops = [];
    var begin = Alignment.bottomCenter;
    var end = Alignment.topCenter;
    bool firstPart = true;
    for (final part in parts) {
      // First part is a direction instruction or an angel
      if (firstPart) {
        firstPart = false;
        if (part.startsWith('to ')) {
          final degree = _parseGradientTo(part);
          begin = convertDegreeToAlignment(degree);
          end = convertDegreeToAlignment(degree + 180);
        } else {
          final degree = FssAngle.parse(part).getDegree();
          begin = convertDegreeToAlignment(degree);
          end = convertDegreeToAlignment(degree + 180);
        }
        continue;
      }

      final colStop = splitValues(this, part);
      colors.add(
        parseColorDef(
          FssPropertyValue('color', colStop[0], imageDef.lineNo),
        ),
      );
      if (colStop.length == 1) {
        // Only color defined. Put a placeholder as stop to interpolate later.
        stops.add(-1);
      }
      if (colStop.length > 1) {
        // Color and stop defined
        stops.add(
          parsePercent(
            FssPropertyValue('stop', colStop[1], imageDef.lineNo),
          ),
        );
      }
      if (colStop.length > 2) {
        // Two stop definition
        colors.add(
          parseColorDef(
            FssPropertyValue('color', colStop[0], imageDef.lineNo),
          ),
        );
        stops.add(
          parsePercent(
            FssPropertyValue('stop', colStop[2], imageDef.lineNo),
          ),
        );
      }
    }
    // Interpolate missing values
    if (stops.isNotEmpty && stops[0] == -1) stops[0] = 0;
    if (stops.isNotEmpty && stops[stops.length - 1] == -1) {
      stops[stops.length - 1] = 1.0;
    }
    // TODO interpolate values if -1

    return LinearGradient(colors: colors, stops: stops, begin: begin, end: end);
  }

  RadialGradient _parseRadialGradient(
    String propValue,
    FssPropertyValue imageDef,
  ) {
    final spec = propValue.substring(
      propValue.indexOf('(') + 1,
      propValue.lastIndexOf(')'),
    );
    final parts = splitFunctionParams(this, spec);

    final List<Color> colors = [];
    final List<double> stops = [];
    // final begin = Alignment.bottomCenter;
    // final end = Alignment.topCenter;
    for (final part in parts) {
      // TODO First part is special

      final colStop = splitValues(this, part);
      // TODO resolve split values
      colors.add(
        parseColorDef(
          FssPropertyValue('color', colStop[0], imageDef.lineNo),
        ),
      );
      if (colStop.length == 1) {
        // Only color defined. Put a placeholder as stop to interpolate later.
        stops.add(-1);
      }
      if (colStop.length > 1) {
        // Color and stop defined
        stops.add(
          parsePercent(
            FssPropertyValue('stop', colStop[1], imageDef.lineNo),
          ),
        );
      }
      if (colStop.length > 2) {
        // Two stop definition
        colors.add(
          parseColorDef(
            FssPropertyValue('color', colStop[0], imageDef.lineNo),
          ),
        );
        stops.add(
          parsePercent(
            FssPropertyValue('stop', colStop[2], imageDef.lineNo),
          ),
        );
      }
    }
    // Interpolate missing values
    if (stops.isNotEmpty && stops[0] == -1) stops[0] = 0;
    if (stops.isNotEmpty && stops[stops.length - 1] == -1) {
      stops[stops.length - 1] = 1.0;
    }
    // TODO interpolate values if -1

    // Where do we get the actual size from
    // const width = 100.0;
    // const height = 100.0;
    const radius = 1.0;
    const size = 'farthest-corner';
    if (size == 'closest-side') {}
    if (size == 'closest-corner') {}
    if (size == 'farthest-side') {}
    if (size == 'farthest-corner') {}

    return RadialGradient(
      colors: colors,
      stops: stops,
      radius: radius,
    );
  }

  /// Get the pattern for the dashed border
  List<double> _dashedBorderPattern() {
    final dashDef = get(FssProperty.fss_dashed_pattern.name);
    if (dashDef != null) {
      final values = splitValues(this, dashDef.value);
      return values.map(double.parse).toList();
    }
    return [8.0, 8.0];
  }

  CircularIntervalList<double>? _parseBorderPattern(
    BorderSide side,
    String? style,
  ) {
    if (style == null) {
      return null;
    }
    return switch (style) {
      'dashed' => CircularIntervalList(_dashedBorderPattern()),
      'dotted' => CircularIntervalList([side.width, side.width]),
      'solid' || 'inset' || 'outset' => CircularIntervalList([100000000.0]),
      _ => null
    };
  }

  /// Manipulates the input content in line with the "text_transform" property
  String _applyTextTransform(String input) {
    final textTransform = get(FssProperty.text_transform.name);
    return applyTextTransform(textTransform, input);
  }

  /// Replaces the input content in line with the "content" property
  String _replaceContent(String input) {
    final contentMode = get(FssProperty.content.name);
    return replaceContent(contentMode, input);
  }

  /// Parses a gradient to definition
  /// Returns the value as degree.
  double _parseGradientTo(String to) {
    final parts = splitValues(this, to);
    parts.removeAt(0);
    parts.sort();
    final dir = parts.fold('', (prev, next) => '$prev $next').trim();
    return parseGradientTo(dir);
  }
}
