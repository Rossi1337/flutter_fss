import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:fss/src/exception/fss_parse_exception.dart';

/// Defines a angel as used by gradient definitions.
@immutable
class FssAngle {
  static const double _degToRad = pi / 180.0;
  static const double _gradToRad = 0.015708;
  static const double _turnToRad = 2 * pi;
  static const double _radToDeg = 180 / pi;

  final double value;
  final String unit;

  /// Creates a new [FssAngle] with the given [value] and [unit].
  /// The [unit] is optional and can be either 'deg', 'rad', 'grad' or 'turn'.
  /// If no unit is given, it defaults to 'deg'.
  /// The [value] is the angle value in the given unit.
  const FssAngle(this.value, [String? unit]) : unit = unit ?? 'deg';

  /// The radians for the angle.
  double getRadians() => switch (unit) {
        'deg' => value * _degToRad,
        'rad' => value,
        'grad' => value * _gradToRad,
        'turn' => value * _turnToRad,
        _ => throw FssParseException('Unit not supported: $unit')
      };

  /// Get the value as degree
  double getDegree() => getRadians() * _radToDeg;

  /// Get the value as radian
  factory FssAngle.parse(String def) {
    final m = RegExp(r'([+-]?[0-9\.]+)([a-z]*)').matchAsPrefix(def.trim());
    if (m != null) {
      return FssAngle(double.parse(m.group(1)!), m.group(2));
    }
    throw FssParseException('Invalid angle value: $def');
  }

  @override
  String toString() => 'FssAngle(value: $value, unit: $unit)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FssAngle &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          unit == other.unit;

  @override
  int get hashCode => Object.hash(value, unit);
}
