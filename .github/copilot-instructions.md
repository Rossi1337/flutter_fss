## Quick orientation

- Purpose: `flutter_fss` is a Dart/Flutter package that implements a CSS-like styling system for Flutter widgets (FSS = Flutter Style Sheets). The runtime consists of a parser (converts FSS text into rules), a `FlutterStyleSheet` resolver (merges matches and handles media queries), and a set of widgets that consume resolved `FssRuleBlock`s to build UI.

## Big-picture architecture (what to read first)

- Entry points / public API:
  - `lib/fss.dart` — package exports and main convenience classes.
  - `lib/src/fss.dart` — `Fss` factory class and `resolveApplicableStyles` helper.

- Theme / resolution pipeline:
  - `lib/src/widgets/fss_theme.dart` — installs a `FlutterStyleSheet` into the widget tree (`FssTheme.of(context)`), factories `withAppDefaults` / `withHtmlDefaults`.
  - `lib/src/parser/fss_stylesheet.dart` — `FlutterStyleSheet` holds parsed rules and merges matches via `resolveStyles(...)`.
  - `lib/src/parser/fss_parser.dart` — `parseStylesheet(...)` converts source FSS text into `FssRule` / `FssRuleBlock` objects (shorthand parsing, media rules, etc.).

- Consumer-side:
  - `lib/src/widgets/fss_widget.dart` — base class all FSS-aware widgets extend; it resolves styles via `resolveApplicableStyles(...)` and exposes `buildContent(context, FssRuleBlock)`.
  - `lib/src/widgets/*` — concrete widgets (`fss_block.dart`, `fss_span.dart`, `fss_list.dart`) that map FSS properties to Flutter constructs using `FssRuleBlock` getters (e.g. `textStyle`, `backgroundImage`, `border`).

## Key conventions & patterns (project-specific)

- Selectors and runtime matching
  - Types are plain strings: `fssType` often comes from `FssType` or `T.toString().toLowerCase()` in `Fss<T>`.
  - Classes are space-separated strings stored in `fssClass`. `FlutterStyleSheet.resolveStyles` expects a string and splits it into `.class` tokens.
  - IDs: `fssID` or fallback to a `ValueKey` string via `FssWidget.getIDForResolve()`.

- Property naming and variables
  - Properties follow CSS-style kebab-case names and are listed in `lib/src/parser/fss_property.dart` (see `FssProperty`).
  - Internal/runtime properties use `-fss-` prefix. CSS variables use `--` prefix (see `FssProperty.varPrefix`).

- Parsing & shorthands
  - `parseStylesheet` in `fss_parser.dart` supports block comments, `@media` rules (creates `FssMediaRule` entries), shorthand expansion (the `_shorthandParsers` map), and function-like values (e.g. `linear-gradient(...)`).
  - When adding a new shorthand or property you must update `FssProperty` (name + initial value) and, if needed, add a shorthand handler in `_shorthandParsers` inside `fss_parser.dart` and conversion logic in `fss_rule_block.dart`.

## Integration points & where to change behavior

- To change how styles are resolved or merged: edit `lib/src/parser/fss_stylesheet.dart::resolveStyles`.
- To add/rename a property: update `lib/src/parser/fss_property.dart` (and its initial defaults via `getInitialValues()`), add parsing/normalization in `lib/src/parser/fss_parser.dart` and consumption in `lib/src/parser/fss_rule_block.dart`.
- To add a widget-level behavior that consumes style values: update or add a widget in `lib/src/widgets/` and use `FssRuleBlock` getters (e.g. `textStyle`, `border`, `padding`).

## Developer workflows (commands & tips)

- Install deps: `flutter pub get` (root) — package is a Flutter package.
- Run unit tests: `flutter test` (root). There is at least `test/fss_parser_test.dart`.
- Run the example app: `cd example` then `flutter run` (choose device). The `example/README.md` contains assets and a simple demo.
- Lint / static analysis: `dart analyze` or `flutter analyze` from root.

Notes:
  - Use `FssTheme.withAppDefaults(..., context: ...)` to bootstrap a theme with Material-derived variables.
  - For diagnostic output: call `FssTheme.of(context).toString(minLevel: DiagnosticLevel.fine)` (the `toString` override adds `getDebugThemeInfo()` when `fine`) to dump rules + defaults.

## Common tasks & where to look for examples

- How FSS text becomes UI:
  - Example flow: `FssTheme` (created with `.withHtmlDefaults` or plain `FssTheme`) → `FlutterStyleSheet` parses text via `parseStylesheet()` → widget tree `FssWidget` calls `resolveApplicableStyles()` → returns `FssRuleBlock` used by `fss_block.dart` / `fss_span.dart` to build Flutter widgets.

- Adding a new CSS-like property:
  1. Add enum entry and initial value in `lib/src/parser/fss_property.dart`.
  2. Add parsing/short-hand expansion in `lib/src/parser/fss_parser.dart` if required.
  3. Expose a typed getter in `lib/src/parser/fss_rule_block.dart` that converts `FssPropertyValue` to Flutter types (Color, double, EdgeInsets, TextStyle, etc.).
  4. Add unit tests under `test/` showing parsing + resolution.

## Files to open first (quick map)

- `lib/src/parser/fss_parser.dart` — parser + helpers (colors, gradients, shorthand map)
- `lib/src/parser/fss_stylesheet.dart` — rule resolver + media handling
- `lib/src/parser/fss_property.dart` — canonical property list and defaults
- `lib/src/parser/fss_rule_block.dart` — conversion from property values to Flutter types
- `lib/src/widgets/fss_theme.dart` and `lib/src/widgets/fss_widget.dart` — how widgets obtain style data

If anything in here is unclear or you'd like more examples (e.g., a short checklist and a unit-test template for adding a property), tell me which area to expand and I'll iterate.
