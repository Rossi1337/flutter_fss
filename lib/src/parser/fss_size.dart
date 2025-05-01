import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:fss/src/exception/fss_parse_exception.dart';
import 'package:fss/src/parser/fss_base.dart';

/// Defines a length / size with unit
///
/// You can use the [getPixelSize] method to convert the value from any unit
/// to a size in virtual pixel.
@immutable
class FssSize {
  /// The default pixel density for web browsers.
  static const ppi = 96;

  /// Default font size in web browser 16
  static const baseFontSize = 16.0;

  /// The conversion factor for sp to rem.
  static const spToRem = 0.0625; // 1sp = 0.0625rem

  /// The value of the size.
  final double value;

  /// The unit of the size.
  final String? unit;

  /// Creates a new [FssSize] with the given [value] and [unit].
  /// The [unit] is optional and can be either 'px', 'em', 'rem', 'in' etc.
  const FssSize(this.value, this.unit);

  /// The calculated size in Logical Pixels
  /// 1 in = 96px = 2.54cm = 25.4mm = 72pt = 6pc
  double getPixelSize(FssBase base) => switch (unit) {
        'in' => value * ppi,
        'em' => value * base.em,
        'ex' => value * base.em * 0.5, // not exact but ok.
        'rem' => value * base.rem,
        '' || 'px' => value,
        'dpi' => value, // used for media query
        'dppx' || 'x' => value,
        'absolute' => base.rem + value,
        'relative' => base.em + value,
        'vw' => value * base.vw,
        'vh' => value * base.vh,
        'vmin' => value * min(base.vw, base.vh),
        'vmax' => value * max(base.vw, base.vh),
        _ => throw FssParseException('Unit not supported: $unit')
      };

  /// Parse a size definition from a string.
  /// The string can be a size with unit or a special size like 'medium', 'small', etc.
  factory FssSize.parse(String def) => switch (def) {
        'medium' => const FssSize(0, 'absolute'),
        'small' => const FssSize(-1, 'absolute'),
        'x-small' => const FssSize(-2, 'absolute'),
        'xx-small' => const FssSize(-3, 'absolute'),
        'large' => const FssSize(1, 'absolute'),
        'x-large' => const FssSize(2, 'absolute'),
        'xx-large' => const FssSize(3, 'absolute'),
        'xxx-large' => const FssSize(4, 'absolute'),
        'larger' => const FssSize(1, 'relative'),
        'smaller' => const FssSize(-1, 'relative'),
        _ => _parseSize(def),
      };

  static FssSize _parseSize(String def) {
    final m = RegExp(r'([+-]?[0-9\.]+)([a-z%]*)').matchAsPrefix(def.trim());
    if (m != null) {
      return FssSize(double.parse(m.group(1)!), m.group(2));
    }
    throw FssParseException('Invalid size value: $def');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FssSize &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          unit == other.unit;

  @override
  int get hashCode => Object.hash(value, unit);

  @override
  String toString() => 'FssValue: $value${unit ?? ''}';
}
