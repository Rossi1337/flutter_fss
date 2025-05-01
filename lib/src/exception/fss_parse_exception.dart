import 'package:fss/src/parser/fss_property_value.dart';

/// An exception thrown if the parsing of the stylesheet or rules fails.
class FssParseException implements Exception {
  final String message;

  /// Creates a new [FssParseException] with the given message.
  const FssParseException(this.message);

  /// Creates a new [FssParseException] for the given property value.
  const FssParseException.forValue(FssPropertyValue value)
      : message = 'Unsupported value $value';

  @override
  String toString() => 'FssException -> $message';
}
