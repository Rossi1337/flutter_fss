import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

/// Reads variables (with --mat- prefix) and rules from the provided FSS theme
/// and creates a Material ThemeData.
class MaterialThemeBuilder {
  late FssRuleBlock _materialRules;

  /// Initializes the builder with the provided FSS theme and extracts the relevant
  /// rules for the material theme.
  MaterialThemeBuilder(FssTheme fssTheme) {
    _materialRules =
        fssTheme.stylesheet.resolveStyles(matchType: 'material-theme');
  }

  /// Creates a ThemeData from the CSS variables defined in the provided FSS theme.
  /// It reads various color and brightness variables and maps them to the corresponding
  /// properties in ThemeData. To create a color scheme from a seed color, use the
  /// `color-seed` variable and optionally `color-brightness`, `color-contrast-level`,
  /// and `color-scheme-variant` variables. If a seed color is provided, the color scheme will
  /// be generated based on that seed color and the other parameters.
  /// If not, a default color scheme will be used.
  /// See also the [ColorScheme.fromSeed].
  ThemeData buildThemeData() {
    return ThemeData(
      brightness: _brightness('brightness'),
      primaryColor: _color('color-primary'),
      primaryColorDark: _color('primary-color-dark'),
      primaryColorLight: _color('primary-color-light'),
      canvasColor: _color('canvas-color'),
      cardColor: _color('card-color'),
      dividerColor: _color('divider-color'),
      disabledColor: _color('disabled-color'),
      focusColor: _color('focus-color'),
      highlightColor: _color('highlight-color'),
      hintColor: _color('hint-color'),
      hoverColor: _color('hover-color'),
      scaffoldBackgroundColor: _color('scaffold-background-color'),
      secondaryHeaderColor: _color('secondary-header-color'),
      shadowColor: _color('shadow-color'),
      splashColor: _color('splash-color'),
      unselectedWidgetColor: _color('unselected-widget-color'),
      colorScheme: _mapColorTheme(),
    );
  }

  /// Maps the CSS variables to a Material ColorScheme.
  ColorScheme _mapColorTheme() {
    ColorScheme result;

    // Create from seed or base theme.
    final seedColor = _color('color-seed');
    if (seedColor != null) {
      result = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: _brightness('color-brightness'),
        contrastLevel: _contrastLevel('color-contrast-level'),
        dynamicSchemeVariant: _dynamicSchemeVariant('color-scheme-variant'),
      );
    } else {
      result = const ColorScheme(
        brightness: Brightness.light,
        primary: Colors.blue,
        onPrimary: Colors.white,
        secondary: Colors.purple,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      );
    }

    // We override the generated color scheme with any
    // explicitly defined colors in the CSS variables.
    return result.copyWith(
      brightness: _brightness('color-brightness'),
      primary: _color('color-primary'),
      onPrimary: _color('color-onprimary'),
      primaryContainer:
          _color('color-primarycontainer') ?? _color('color-primaryvariant'),
      onPrimaryContainer: _color('color-onprimarycontainer'),
      primaryFixed: _color('color-primaryfixed'),
      primaryFixedDim: _color('color-primaryfixeddim'),
      onPrimaryFixed: _color('color-onprimaryfixed'),
      onPrimaryFixedVariant: _color('color-onprimaryfixedvariant'),
      secondary: _color('color-secondary'),
      onSecondary: _color('color-onsecondary'),
      secondaryContainer: _color('color-secondarycontainer') ??
          _color('color-secondaryvariant'),
      onSecondaryContainer: _color('color-onsecondarycontainer'),
      secondaryFixed: _color('color-secondaryfixed'),
      secondaryFixedDim: _color('color-secondaryfixeddim'),
      onSecondaryFixed: _color('color-onsecondaryfixed'),
      onSecondaryFixedVariant: _color('color-onsecondaryfixedvariant'),
      tertiary: _color('color-tertiary'),
      onTertiary: _color('color-ontertiary'),
      tertiaryContainer: _color('color-tertiarycontainer'),
      onTertiaryContainer: _color('color-ontertiarycontainer'),
      tertiaryFixed: _color('color-tertiaryfixed'),
      tertiaryFixedDim: _color('color-tertiaryfixeddim'),
      onTertiaryFixed: _color('color-ontertiaryfixed'),
      onTertiaryFixedVariant: _color('color-ontertiaryfixedvariant'),
      error: _color('color-error'),
      onError: _color('color-onerror'),
      errorContainer: _color('color-errorcontainer'),
      onErrorContainer: _color('color-onerrorcontainer'),
      surface: _color('color-surface'),
      onSurface: _color('color-onsurface'),
      surfaceDim: _color('color-surfacedim'),
      surfaceBright: _color('color-surfacebright'),
      surfaceContainerLowest: _color('color-surfacecontainerlowest'),
      surfaceContainerLow: _color('color-surfacecontainerlow'),
      surfaceContainer: _color('color-surfacecontainer'),
      surfaceContainerHigh: _color('color-surfacecontainerhigh'),
      surfaceContainerHighest: _color('color-surfacecontainerhighest'),
      onSurfaceVariant: _color('color-onsurfacevariant'),
      outline: _color('color-outline'),
      outlineVariant: _color('color-outlinevariant'),
      shadow: _color('color-shadow'),
      scrim: _color('color-scrim'),
      inverseSurface: _color('color-inversesurface'),
      onInverseSurface: _color('color-oninversesurface'),
      inversePrimary: _color('color-inverseprimary'),
      surfaceTint: _color('color-surfacetint'),
    );
  }

  double _contrastLevel(String name) =>
      double.tryParse(_get(name) ?? '0.0') ?? 0.0;

  String? _get(String name) => _materialRules.get('--mat-$name')?.value;

  Color? _color(String name) => _materialRules.getColor('--mat-$name');

  Brightness _brightness(String name) {
    final v = _materialRules.get('--mat-$name')?.value;
    return v == 'dark' ? Brightness.dark : Brightness.light;
  }

  DynamicSchemeVariant _dynamicSchemeVariant(String s) {
    final value = _get(s);
    switch (value) {
      case 'expressive':
        return DynamicSchemeVariant.expressive;
      case 'fidelity':
        return DynamicSchemeVariant.fidelity;
      case 'content':
        return DynamicSchemeVariant.content;
      case 'fruit-salad':
        return DynamicSchemeVariant.fruitSalad;
      case 'monochrome':
        return DynamicSchemeVariant.monochrome;
      case 'neutral':
        return DynamicSchemeVariant.neutral;
      case 'rainbow':
        return DynamicSchemeVariant.rainbow;
      case 'vibrant':
        return DynamicSchemeVariant.vibrant;
      default:
        return DynamicSchemeVariant.tonalSpot;
    }
  }
}
