import 'package:flutter/foundation.dart';

/// Simple helper class to represent a property value definition as parsed from
/// a style sheet.
@immutable
class FssPropertyValue {
  final String name;
  final String value;
  final int lineNo;

  /// Creates a new [FssPropertyValue] with the given [name], [value], and
  /// optional [lineNo].
  const FssPropertyValue(
    this.name,
    this.value, [
    this.lineNo = -1,
  ]);

  /// Creates a new [FssPropertyValue] with the same name and line number but a
  /// different value.
  FssPropertyValue subValue(String subValue) =>
      FssPropertyValue(name, subValue, lineNo);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FssPropertyValue &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          value == other.value &&
          lineNo == other.lineNo;

  @override
  int get hashCode => Object.hash(name, value, lineNo);

  @override
  String toString() => '"$value" for property "$name" (line $lineNo)';
}
