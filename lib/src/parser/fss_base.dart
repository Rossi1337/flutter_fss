import 'package:flutter/foundation.dart';
import 'package:fss/src/parser/fss_size.dart';

/// Stores baseline values for size conversion.
///
/// This class provides calculated values for `rem`, `em`, `vw`, and `vh`
/// based on the provided screen dimensions and font sizes.
@immutable
class FssBase {
  static const double dummyScreenWidth = 1024;
  static const double dummyScreenHeight = 768;

  /// A fallback instance of [FssBase] with default values.
  static const fallback = FssBase(
    remBase: FssSize.baseFontSize,
    emBase: FssSize.baseFontSize,
    screenWidth: dummyScreenWidth,
    screenHeight: dummyScreenHeight,
  );

  /// The base value for rem units.
  final double rem;

  /// The base value for em units.
  final double em;

  /// The width of 1% of the screen width (vw).
  final double vw;

  /// The height of 1% of the screen height (vh).
  final double vh;

  /// Creates an instance of [FssBase].
  ///
  /// [screenWidth] and [screenHeight] must be positive values.
  const FssBase({
    double? remBase,
    double? emBase,
    required double screenWidth,
    required double screenHeight,
  })  : assert(screenWidth > 0, 'screenWidth must be positive'),
        assert(screenHeight > 0, 'screenHeight must be positive'),
        rem = remBase ?? FssSize.baseFontSize,
        em = emBase ?? FssSize.baseFontSize,
        vw = screenWidth / 100.0,
        vh = screenHeight / 100.0;
}
