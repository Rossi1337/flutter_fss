import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fss/fss.dart';

/// Tests for the `opacity` property (CSS group opacity).
///
/// Covers:
///  - value parsing / clamping via [FssRuleBlock.opacity]
///  - default value
///  - that FSS widgets render a group [Opacity] only when opacity < 1.0
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('opacity parsing', () {
    FssRuleBlock parse(String css) =>
        parseStylesheet('test { $css }').first.properties;

    test('plain number', () {
      expect(parse('opacity: 0.5;').opacity, 0.5);
    });

    test('leading dot number', () {
      expect(parse('opacity: .5;').opacity, 0.5);
    });

    test('opacity 1', () {
      expect(parse('opacity: 1;').opacity, 1.0);
    });

    test('opacity 0', () {
      expect(parse('opacity: 0;').opacity, 0.0);
    });

    test('percentage value', () {
      expect(parse('opacity: 50%;').opacity, 0.5);
    });

    test('clamps above 1', () {
      expect(parse('opacity: 150%;').opacity, 1.0);
      expect(parse('opacity: 1.5;').opacity, 1.0);
    });

    test('clamps below 0', () {
      expect(parse('opacity: -20%;').opacity, 0.0);
      expect(parse('opacity: -0.2;').opacity, 0.0);
    });
  });

  group('opacity default', () {
    test('defaults to 1.0 when not set', () {
      final styles = parseStylesheet('test { color: red; }').first.properties;
      expect(styles.opacity, 1.0);
    });
  });

  group('opacity widget rendering', () {
    testWidgets('Fss.div renders an Opacity when opacity < 1',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FssTheme(
            stylesheet: '.box { opacity: 0.4; }',
            child: Fss.div(clazz: 'box', child: const Text('hello')),
          ),
        ),
      );

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((w) => w.opacity)
          .toList();
      expect(opacities, contains(0.4));
    });

    testWidgets('no FSS Opacity is added when opacity is not set',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FssTheme(
            stylesheet: '.box { color: red; }',
            child: Fss.div(clazz: 'box', child: const Text('hello')),
          ),
        ),
      );

      // FSS must not wrap the content in an Opacity at full/partial opacity.
      final fssOpacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((w) => w.opacity)
          .where((o) => o < 1.0)
          .toList();
      expect(fssOpacities, isEmpty);
    });

    testWidgets('nested FSS widgets each contribute their own Opacity',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FssTheme(
            stylesheet: 'div { opacity: 0.5; }',
            child: Fss.div(child: Fss.div(child: const Text('inner'))),
          ),
        ),
      );

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((w) => w.opacity)
          .where((o) => o < 1.0)
          .toList();
      // Both the outer and inner div are at opacity 0.5 and both are wrapped.
      expect(opacities.where((o) => o == 0.5).length, 2);
    });
  });
}
