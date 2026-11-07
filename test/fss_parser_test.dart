import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fss/fss.dart';
import 'package:fss/src/default/fss_html_css.dart';

/// All kind of unit tests for the parser.

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // -------------------------------------------------------------
  // Tests for basic parsing functions
  // -------------------------------------------------------------

  group('Generic Parsing', () {
    // -------------------------------------------------------------
    test('Parse size px', () {
      const input = '''
        test { 
          width: 3px; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.width, 3);
    });

    // -------------------------------------------------------------
    test('Parse size in', () {
      const input = '''
        test { 
          width: 3in; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.width, 288);
    });

    // -------------------------------------------------------------
    test('Parse size em', () {
      const input = '''
        test {
          font-size: 16; 
          width: 2em; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.width, 32);
    });

    // -------------------------------------------------------------
    test('Parse size em', () {
      const input = '''
        test {
          width: 2rem; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.width, 32);
    });

    // -------------------------------------------------------------
    test('Parse shorthand', () {
      const input = '''
        test { 
          border: 3px solid black; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.border?.top.color, const Color(0xff000000));
      expect(styles.border?.top.style, BorderStyle.solid);
      expect(styles.border?.top.width, 3);
    });

    // -------------------------------------------------------------
    test('Parse shorthand with function', () {
      const input = '''
        test { 
          border: 3px solid rgb(0, 0, 255); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.border?.top.color, const Color(0xff0000ff));
      expect(styles.border?.top.style, BorderStyle.solid);
      expect(styles.border?.top.width, 3);
    });

    // -------------------------------------------------------------
    test('Parse shorthand with var', () {
      const input = '''
        test { 
          --mycolor: blue; 
          border: 3px solid var(--mycolor); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.border?.top.color, const Color(0xff0000ff));
      expect(styles.border?.top.style, BorderStyle.solid);
      expect(styles.border?.top.width, 3);
    });

    // -------------------------------------------------------------
    test(
      'Parse var in function',
      () {
        const input = '''
        test { 
          --zero: 0; 
          border: 3px solid rgb( var(--zero), 0, 0); 
        } ''';
        final styles = parseStylesheet(input).first.properties;
        expect(styles.border?.top.color, const Color(0xff000000));
        expect(styles.border?.top.style, BorderStyle.solid);
        expect(styles.border?.top.width, 3);
      },
      skip: true, // Not yet working
    );
  });

// -------------------------------------------------------------
  // Tests for specific property parsing
  // -------------------------------------------------------------

  group('Property Parsing', () {
    // -------------------------------------------------------------
    test('Parse color hex8', () {
      const input = '''
        test { 
          color: #FF0000FF;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.color, const Color.fromARGB(255, 0, 0, 255));
    });

    // -------------------------------------------------------------
    test('Parse color hex6', () {
      const input = '''
        test { 
          color: #0000FF;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.color, const Color.fromARGB(255, 0, 0, 255));
    });

    // -------------------------------------------------------------
    test('Parse color constant', () {
      const input = '''
        test { 
          color: blue;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.color, const Color.fromARGB(255, 0, 0, 255));
    });

    // -------------------------------------------------------------
    test('Parse color from var', () {
      const input = '''
        test {
          --colvar: blue; 
          color: var(--colvar);
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.color, const Color.fromARGB(255, 0, 0, 255));
    });

    // -------------------------------------------------------------
    test('Parse color rgb function', () {
      const input = '''
        test { 
          color: rgb( 0, 0, 255 ); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.color, const Color.fromARGB(255, 0, 0, 255));
    });

    // -------------------------------------------------------------
    test('Parse color rgba function', () {
      const input = '''
        test { 
          color: rgba( 0, 0, 255, 0.5 ); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.color, const Color.fromRGBO(0, 0, 255, 0.5));
    });

    // -------------------------------------------------------------
    test('Parse background-color', () {
      const input = '''
        test { 
          background-color: blue; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundColor, const Color(0xff0000ff));
    });

    // -------------------------------------------------------------
    test('Parse background-image', () {
      const input = '''
        test { 
          background-image: test.png; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundImage?.image, isNotNull);
    });

    // -------------------------------------------------------------
    test('Parse background-image linear-gradient', () {
      const input = '''
        test { 
          background-image: linear-gradient(45deg, red 25%, #00ff00 50%, rgb(0,0,255)); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is LinearGradient, true);
      expect(styles.backgroundGradient?.colors, [
        const Color(0xffff0000),
        const Color(0xff00ff00),
        const Color(0xff0000ff)
      ]);
      expect(styles.backgroundGradient?.stops, [0.25, 0.5, 1.0]);
    });

    // -------------------------------------------------------------
    test('Parse linear-gradient without stops', () {
      const input = '''
        test { 
          background-image: linear-gradient(to right, red, green, blue); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is LinearGradient, true);
      expect(
        styles.backgroundGradient?.colors,
        [
          const Color(0xffff0000),
          const Color(0xff008000),
          const Color(0xff0000ff)
        ],
      );
      expect(styles.backgroundGradient?.stops, [0.0, 0.5, 1.0]);
    });

    // -------------------------------------------------------------
    test('Parse linear-gradient with missing middle stop', () {
      const input = '''
        test { 
          background-image: linear-gradient(to right, red 0%, green, blue 100%); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is LinearGradient, true);
      expect(styles.backgroundGradient?.stops, [0.0, 0.5, 1.0]);
    });

    // -------------------------------------------------------------
    test('Parse linear-gradient with consecutive missing stops', () {
      const input = '''
        test { 
          background-image: linear-gradient(to right, red 0%, green, blue, cyan 100%); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is LinearGradient, true);
      expect(
        styles.backgroundGradient?.stops,
        [0.0, 1 / 3, 2 / 3, 1.0],
      );
    });

    // -------------------------------------------------------------
    test('Parse linear-gradient with missing first stop', () {
      const input = '''
        test { 
          background-image: linear-gradient(to right, red, green 50%, blue 75%); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is LinearGradient, true);
      expect(styles.backgroundGradient?.stops, [0.0, 0.5, 0.75]);
    });

    // -------------------------------------------------------------
    test('Parse linear-gradient with missing last stop', () {
      const input = '''
        test { 
          background-image: linear-gradient(to right, red 25%, green 50%, blue); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is LinearGradient, true);
      expect(styles.backgroundGradient?.stops, [0.25, 0.5, 1.0]);
    });

    // -------------------------------------------------------------
    test('Parse background-image linear-radial', () {
      const input = '''
        test { 
          background-image: radial-gradient(red 25%, #00ff00 50%, rgb(0,0,255)); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is RadialGradient, true);
      expect(styles.backgroundGradient?.colors, [
        const Color(0xffff0000),
        const Color(0xff00ff00),
        const Color(0xff0000ff)
      ]);
      expect(styles.backgroundGradient?.stops, [0.25, 0.5, 1.0]);
    });

    // -------------------------------------------------------------
    test('Parse radial-gradient without stops', () {
      const input = '''
        test { 
          background-image: radial-gradient(red, green, blue); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is RadialGradient, true);
      expect(
        styles.backgroundGradient?.colors,
        [
          const Color(0xffff0000),
          const Color(0xff008000),
          const Color(0xff0000ff)
        ],
      );
      expect(styles.backgroundGradient?.stops, [0.0, 0.5, 1.0]);
    });

    // -------------------------------------------------------------
    test('Parse radial-gradient with missing middle stop', () {
      const input = '''
        test { 
          background-image: radial-gradient(red 0%, green, blue 100%); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is RadialGradient, true);
      expect(styles.backgroundGradient?.stops, [0.0, 0.5, 1.0]);
    });

    // -------------------------------------------------------------
    test('Parse radial-gradient with consecutive missing stops', () {
      const input = '''
        test { 
          background-image: radial-gradient(red 0%, green, blue, cyan 100%); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is RadialGradient, true);
      expect(
        styles.backgroundGradient?.stops,
        [0.0, 1 / 3, 2 / 3, 1.0],
      );
    });

    // -------------------------------------------------------------
    test('Parse radial-gradient with missing first stop', () {
      const input = '''
        test { 
          background-image: radial-gradient(red, green 50%, blue 75%); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is RadialGradient, true);
      expect(styles.backgroundGradient?.stops, [0.0, 0.5, 0.75]);
    });

    // -------------------------------------------------------------
    test('Parse radial-gradient with missing last stop', () {
      const input = '''
        test { 
          background-image: radial-gradient(red 25%, green 50%, blue); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is RadialGradient, true);
      expect(styles.backgroundGradient?.stops, [0.25, 0.5, 1.0]);
    });

    // -------------------------------------------------------------
    test('Parse radial-gradient with var stops and colors', () {
      const input = '''
        test { 
          --stop: 50%; 
          --color: green; 
          background-image: radial-gradient(red 0%, var(--color) var(--stop), blue 100%); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is RadialGradient, true);
      expect(
        styles.backgroundGradient?.colors,
        [
          const Color(0xffff0000),
          const Color(0xff008000),
          const Color(0xff0000ff)
        ],
      );
      expect(styles.backgroundGradient?.stops, [0.0, 0.5, 1.0]);
    });

    // -------------------------------------------------------------
    test('Parse background-image sweep-gradient', () {
      const input = '''
        test { 
          background-image: sweep-gradient(red, #00ff00 50%, rgb(0,0,255)); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is SweepGradient, true);
      expect(styles.backgroundGradient?.colors, [
        const Color(0xffff0000),
        const Color(0xff00ff00),
        const Color(0xff0000ff)
      ]);
      expect(styles.backgroundGradient?.stops, [0.0, 0.5, 1.0]);
    });

    // -------------------------------------------------------------
    test('Parse background-image sweep-gradient with from angle', () {
      const input = '''
        test { 
          background-image: sweep-gradient(from 90deg, red, blue); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is SweepGradient, true);
      final g = styles.backgroundGradient! as SweepGradient;
      expect(g.colors, [
        const Color(0xffff0000),
        const Color(0xff0000ff)
      ]);
      // The sweep always paints the full circle [0, 2π); the start position
      // is expressed as a rotation, not by shifting the angle sector.
      expect(g.startAngle, 0.0);
      expect(g.endAngle, 2 * math.pi);
      // from 90deg points at 3 o'clock, where a non-rotated sweep already
      // starts, so the rotation is zero.
      expect(g.transform, const GradientRotation(0.0));
    });

    // -------------------------------------------------------------
    test('Parse background-image sweep-gradient without from angle', () {
      const input = '''
        test { 
          background-image: sweep-gradient(red, blue); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.backgroundGradient is SweepGradient, true);
      final g = styles.backgroundGradient! as SweepGradient;
      // No angle: the default is 'from 0deg' which is 12 o'clock. The sweep
      // still paints [0, 2π); the seam is moved from its default 3 o'clock
      // position up to 12 o'clock by rotating -90°.
      expect(g.startAngle, 0.0);
      expect(g.endAngle, 2 * math.pi);
      final rotation = g.transform! as GradientRotation;
      expect(rotation.radians, closeTo(-math.pi / 2, 1e-9));
    });

    // -------------------------------------------------------------
    test('Parse background-image sweep-gradient does not create an image', () {
      const input = '''
        test { 
          background-image: sweep-gradient(from 45deg, red, blue); 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      // The sweep is exposed as a gradient ...
      expect(styles.backgroundGradient is SweepGradient, true);
      // ... and must NOT also be turned into a DecorationImage, because
      // background images paint on top of gradients and would hide it.
      expect(styles.backgroundImage, isNull);
    });

    // -------------------------------------------------------------
    test('Parse border', () {
      const input = '''
        test { 
          border: 3px solid black; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.border?.top.color, const Color(0xff000000));
      expect(styles.border?.top.style, BorderStyle.solid);
      expect(styles.border?.top.width, 3);
    });

    // -------------------------------------------------------------
    test('Parse border side', () {
      const input = '''
        test { 
          border-top: 3px solid black; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.border?.top.color, const Color(0xff000000));
      expect(styles.border?.top.style, BorderStyle.solid);
      expect(styles.border?.top.width, 3);
    });

    // -------------------------------------------------------------
    test('Parse border side values', () {
      const input = '''
        test { 
          border-top-width: 3px; 
          border-top-color: black; 
          border-top-style: solid; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.border?.top.color, const Color(0xff000000));
      expect(styles.border?.top.style, BorderStyle.solid);
      expect(styles.border?.top.width, 3);
    });

    // -------------------------------------------------------------
    test('Parse border radius', () {
      const input = '''
        test { 
          border-radius: 5px; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.borderRadius, BorderRadius.circular(5));
    });

    // -------------------------------------------------------------
    test('Parse font3', () {
      const input = '''
        test { 
          font: bold 16px Roboto; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.fontSize, 16);
      expect(styles.textStyle?.fontWeight, FontWeight.bold);
      expect(styles.textStyle?.fontFamily, 'Roboto');
    });

    // -------------------------------------------------------------
    test('Parse font4', () {
      const input = '''
        test { 
          font: italic bold 16px Roboto; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.fontStyle, FontStyle.italic);
      expect(styles.textStyle?.fontSize, 16);
      expect(styles.textStyle?.fontWeight, FontWeight.bold);
      expect(styles.textStyle?.fontFamily, 'Roboto');
    });

    // -------------------------------------------------------------
    test('Parse font with fallback', () {
      const input = '''
        test { 
          font-family: Roboto, SansSerif; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.fontFamily, 'Roboto');
      expect(styles.textStyle?.fontFamilyFallback?[0], 'SansSerif');
    });

    // -------------------------------------------------------------
    test('Parse text-decoration', () {
      const input = '''
        test { 
          text-decoration-color: blue; 
          text-decoration-line: underline; 
          text-decoration-style: wavy; 
          text-decoration-thickness: 3px; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.decorationColor, const Color(0xff0000ff));
      expect(styles.textStyle?.decoration, TextDecoration.underline);
      expect(styles.textStyle?.decorationStyle, TextDecorationStyle.wavy);
      expect(styles.textStyle?.decorationThickness, 3);
    });

    // -------------------------------------------------------------
    test('Parse outline', () {
      const input = '''
        test { 
          text-stroke: 2px blue; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.foreground?.strokeWidth, 2);
      expect(styles.textStyle?.foreground?.color, const Color(0xff0000ff));
    });

    // -------------------------------------------------------------
    test('Parse letter-spacing', () {
      const input = '''
        test { 
          letter-spacing: 10px; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.letterSpacing, 10);
    });

    // -------------------------------------------------------------
    test('Parse letter-spacing', () {
      const input = '''
        test { 
          word-spacing: 10px; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.wordSpacing, 10);
    });

    // -------------------------------------------------------------
    test('Parse text height', () {
      const input = '''
        test { 
          height: 10px; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textStyle?.height, 10);
    });

    // -------------------------------------------------------------
    test('Parse text-align', () {
      const input = '''
        test { 
          text-align: end; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textAlign, TextAlign.end);
    });

    // -------------------------------------------------------------
    test('Parse vertical-align', () {
      const input = '''
        test { 
          vertical-align: bottom; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.verticalAlign, Alignment.bottomCenter);
    });

    // -------------------------------------------------------------
    test('Parse combined alignment', () {
      const input = '''
        test { 
          text-align: right; 
          vertical-align: bottom; 
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.alignment, Alignment.bottomRight);
    });

    // -------------------------------------------------------------
    test('Parse box-shadow', () {
      const input = '''
        test { 
          box-shadow: 2px 3px 4px 5px blue;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.boxShadow?.offset.dx, 2);
      expect(styles.boxShadow?.offset.dy, 3);
      expect(styles.boxShadow?.blurRadius, 4);
      expect(styles.boxShadow?.spreadRadius, 5);
      expect(styles.boxShadow?.color, const Color(0xff0000ff));
    });

    // -------------------------------------------------------------
    test('Parse content string', () {
      const input = '''
        test { 
          content: "hello world";
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.transformText(''), 'hello world');
    });

    // -------------------------------------------------------------
    test('Parse content string with escaped quote', () {
      const input = '''
        test { 
          content: "say \\"hi\\"";
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.transformText(''), 'say "hi"');
    });

    // -------------------------------------------------------------
    test('Parse content string with backslash escape', () {
      const input = '''
        test { 
          content: "a\\\\b";
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.transformText(''), 'a\\b');
    });

    // -------------------------------------------------------------
    test('Parse content string with simple escape', () {
      const input = '''
        test { 
          content: "line\\nbreak";
        } ''';
      // In CSS (unlike JS) a simple escape like \n drops the backslash
      // and keeps the character, so this is not a line break.
      final styles = parseStylesheet(input).first.properties;
      expect(styles.transformText(''), 'linenbreak');
    });

    // -------------------------------------------------------------
    test('Parse content string with hex escape', () {
      const input = '''
        test { 
          content: "\\201c";
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.transformText(''), '\u201c');
    });

    // -------------------------------------------------------------
    test('Parse visibility', () {
      const input = '''
        test { 
          visibility: hidden;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.visible, false);
    });

    // -------------------------------------------------------------
    test('Parse content-visibility', () {
      const input = '''
        test { 
          content-visibility: hidden;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.contentVisible, false);
    });

    // -------------------------------------------------------------
    test('Parse text-overflow', () {
      const input = '''
        test { 
          text-overflow: fade;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.textOverflow, TextOverflow.fade);
    });

    // -------------------------------------------------------------
    test('Parse white-space', () {
      const input = '''
        test { 
          white-space: nowrap;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.whiteSpace, 'nowrap');
      expect(styles.wrapText, false);
    });

    // -------------------------------------------------------------
    test('Parse direction', () {
      const input = '''
        test { 
          direction: rtl;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.direction, TextDirection.rtl);
    });

    // -------------------------------------------------------------
    test('Parse line-height', () {
      const input = '''
        test { 
           line-height: 11px;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.lineHeight, 11);
    });

    // -------------------------------------------------------------
    test('Parse sizes', () {
      const input = '''
        test { 
           min-height: 8px;
           height: 9px;
           max-height: 10px;
           min-width: 11px;
           width: 12px;
           max-width: 13px;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.minHeight, 8);
      expect(styles.height, 9);
      expect(styles.maxHeight, 10);
      expect(styles.minWidth, 11);
      expect(styles.width, 12);
      expect(styles.maxWidth, 13);
      expect(
        styles.constraints,
        const BoxConstraints(
          minHeight: 8,
          maxHeight: 10,
          minWidth: 11,
          maxWidth: 13,
        ),
      );
    });

    test('Parse relative sizes', () {
      const input = '''
        test { 
           min-height: 10vh;
           height: 50vh;
           max-height: 100vh;
           min-width: 10vw;
           width: 50vw;
           max-width: 100vw;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.minHeight, FssBase.dummyScreenHeight / 10);
      expect(styles.height, FssBase.dummyScreenHeight / 2);
      expect(styles.maxHeight, FssBase.dummyScreenHeight);
      expect(styles.minWidth, FssBase.dummyScreenWidth / 10);
      expect(styles.width, FssBase.dummyScreenWidth / 2);
      expect(styles.maxWidth, FssBase.dummyScreenWidth);
    });

    // -------------------------------------------------------------
    test('Parse margin', () {
      const input = '''
        test { 
           margin: 10px;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.margin, const EdgeInsets.all(10));
    });

    // -------------------------------------------------------------
    test('Parse padding', () {
      const input = '''
        test { 
           padding: 10px;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.padding, const EdgeInsets.all(10));
    });

    // -------------------------------------------------------------
    test('List style decimal', () {
      const input = '''
        test { 
           list-style-type: decimal;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.getListStyleSymbol(0, 10), '0.');
      expect(styles.getListStyleSymbol(5, 10), '5.');
      expect(styles.getListStyleSymbol(10, 10), '10.');
      expect(styles.getListStyleSymbol(-1, 10), '-1.');
      expect(styles.getListStyleSymbol(5, 100), '5.');
    });
    // -------------------------------------------------------------
    test('List style decimal leading zero', () {
      const input = '''
        test { 
           list-style-type: decimal-leading-zero;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.getListStyleSymbol(0, 10), '00.');
      expect(styles.getListStyleSymbol(5, 10), '05.');
      expect(styles.getListStyleSymbol(10, 10), '10.');
      expect(styles.getListStyleSymbol(-1, 10), '-1.');
      // FIX THIS? expect(styles.getListStyleSymbol(-1, 100), '-1.');
      expect(styles.getListStyleSymbol(5, 100), '005.');
    });
    // -------------------------------------------------------------
    test('List style lower latin', () {
      const input = '''
        test { 
           list-style-type: lower-latin;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.getListStyleSymbol(1, 10), 'a.');
      expect(styles.getListStyleSymbol(5, 10), 'e.');
      expect(styles.getListStyleSymbol(10, 10), 'j.');
      expect(styles.getListStyleSymbol(20, 100), 't.');
      // FIX number > 26 expect(styles.getListStyleSymbol(100, 100), '??.');
    });
    // -------------------------------------------------------------
    test('List style upper roman', () {
      const input = '''
        test { 
           list-style-type: upper-roman;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.getListStyleSymbol(1, 10), 'I.');
      expect(styles.getListStyleSymbol(5, 10), 'V.');
      expect(styles.getListStyleSymbol(10, 10), 'X.');
      expect(styles.getListStyleSymbol(20, 100), 'XX.');
      expect(styles.getListStyleSymbol(100, 100), 'C.');
    });
    // -------------------------------------------------------------
    test('List style lower greek', () {
      const input = '''
        test { 
           list-style-type: lower-greek;
        } ''';
      final styles = parseStylesheet(input).first.properties;
      expect(styles.getListStyleSymbol(1, 10), 'α.');
      expect(styles.getListStyleSymbol(5, 10), 'ε.');
      expect(styles.getListStyleSymbol(10, 10), 'κ.');
      expect(styles.getListStyleSymbol(20, 100), 'τ.');
      expect(styles.getListStyleSymbol(100, 100), 'Д.');
    });
  });

  // -------------------------------------------------------------
  // Selector related test cases
  // -------------------------------------------------------------

  group('Selector Parsing', () {
    // -------------------------------------------------------------
    test('Single class', () {
      final selector = FssSelector.parse('.class1');
      expect(selector.classes[0], '.class1');
    });

    // -------------------------------------------------------------
    test('Multi class', () {
      final selector = FssSelector.parse('.class1.class2');
      expect(selector.classes[0], '.class1');
      expect(selector.classes[1], '.class2');
    });

    // -------------------------------------------------------------
    test('Class with attribute', () {
      final selector = FssSelector.parse('.class1[attribute1].class2');
      expect(selector.classes[0], '.class1[attribute1]');
      expect(selector.classes[1], '.class2');
    });

    // -------------------------------------------------------------
    test('Simple ID', () {
      final selector = FssSelector.parse('#my_id');
      expect(selector.id, '#my_id');
    });

    // -------------------------------------------------------------
    test('Simple type', () {
      final selector = FssSelector.parse('div');
      expect(selector.type, 'div');
    });

    // -------------------------------------------------------------
    test('All combined', () {
      final selector = FssSelector.parse('div.class1.class2#my_id');
      expect(selector.type, 'div');
      expect(selector.classes[0], '.class1');
      expect(selector.classes[1], '.class2');
      expect(selector.id, '#my_id');
    });

    // -------------------------------------------------------------
    test('With virtual "state" class', () {
      final selector = FssSelector.parse('btn:selected');
      expect(selector.type, 'btn');
      expect(selector.classes[0], ':selected');
    });

    // -------------------------------------------------------------
    test('With normal and virtual "state" class', () {
      final selector = FssSelector.parse('btn.class1:selected');
      expect(selector.type, 'btn');
      expect(selector.classes[0], '.class1');
      expect(selector.classes[1], ':selected');
    });

    test(
      'Defined on multiple lines',
      () {
        const input = '''
        t1,
        t2 { 
          font-size: 32px;
        } ''';
        final styles = parseStylesheet(input).first.properties;
        expect(styles.textStyle?.fontSize, 32);
      },
    );
  });

  // -------------------------------------------------------------
  // FlutterStylesheet related test cases
  // -------------------------------------------------------------

  group('Shylesheet methods', () {
    // -------------------------------------------------------------
    test('Parse default stylesheet', () {
      final st = FlutterStyleSheet(stylesheet: htmlCss);
      expect(st.rules.length, greaterThan(0));
    });

    test('Access stylesheet rules', () {
      const input = '''
        test { 
           line-height: 11px;
        }
        test2 { 
           line-height: 12px;
        }
         ''';
      final st = FlutterStyleSheet(stylesheet: input);
      expect(st.rules.length, 2);
    });

    // -------------------------------------------------------------
    test('Check stylesheet defaults', () {
      const input = '''
        test { 
           line-height: 11px;
        }
      ''';
      final st = FlutterStyleSheet(stylesheet: input);
      expect(st.systemDefaults.textStyle?.fontSize, FssSize.baseFontSize);
      expect(st.systemDefaults.color, const Color(0xff000000));
    });
  });

  // -------------------------------------------------------------
  // Single line and robustness tests
  // -------------------------------------------------------------

  group('Single line and robustness', () {
    // -------------------------------------------------------------
    test('Parse single line rule', () {
      final styles = parseStylesheet('test { line-height: 11px; }');
      expect(styles.length, 1);
      expect(styles.first.properties.lineHeight, 11);
    });

    // -------------------------------------------------------------
    test('Parse single line rule without trailing semicolon', () {
      final styles = parseStylesheet('test { line-height: 11px }');
      expect(styles.first.properties.lineHeight, 11);
    });

    // -------------------------------------------------------------
    test('Parse multiple rules on one line', () {
      final styles = parseStylesheet('t1 { color: red; } t2 { color: blue; }');
      expect(styles.length, 2);
      expect(styles[0].properties.color, const Color(0xffff0000));
      expect(styles[1].properties.color, const Color(0xff0000ff));
    });

    // -------------------------------------------------------------
    test('Parse multiple declarations on one line', () {
      final styles = parseStylesheet('test { width: 10px; height: 20px; }');
      final props = styles.first.properties;
      expect(props.width, 10);
      expect(props.height, 20);
    });

    // -------------------------------------------------------------
    test('Parse minified stylesheet', () {
      const input =
          '.a{color:red;font-size:12px}.b{background-image:url(http://example.com/i.png);border-radius:5px}';
      final styles = parseStylesheet(input);
      expect(styles.length, 2);
      expect(styles[0].properties.color, const Color(0xffff0000));
      expect(styles[0].properties.textStyle?.fontSize, 12);
      expect(styles[1].properties.backgroundImage, isNotNull);
      expect(styles[1].properties.borderRadius, BorderRadius.circular(5));
    });

    // -------------------------------------------------------------
    test('Parse value containing a colon', () {
      final styles = parseStylesheet(
          'test { background-image: url(http://example.com/i.png); }');
      expect(styles.first.properties.backgroundImage, isNotNull);
    });

    // -------------------------------------------------------------
    test('Parse important flag', () {
      final styles = parseStylesheet('test { color: red !important; }');
      expect(styles.first.properties.color, const Color(0xffff0000));
    });

    // -------------------------------------------------------------
    test('Parse inline comments', () {
      const input =
          'test { /* before */ color: red; /* middle */ font-size: 10px; } // trailing';
      final styles = parseStylesheet(input);
      expect(styles.first.properties.color, const Color(0xffff0000));
      expect(styles.first.properties.textStyle?.fontSize, 10);
    });

    // -------------------------------------------------------------
    test('Parse block comment containing url', () {
      const input = '''
        /* see http://example.com/ for more
           and // not a comment here */
        test { color: red; }
      ''';
      final styles = parseStylesheet(input);
      expect(styles.length, 1);
      expect(styles.first.properties.color, const Color(0xffff0000));
    });

    // -------------------------------------------------------------
    test('Parse line comment', () {
      const input = '''
        // A comment
        test { color: red; }
        // Another comment
      ''';
      final styles = parseStylesheet(input);
      expect(styles.length, 1);
      expect(styles.first.properties.color, const Color(0xffff0000));
    });

    // -------------------------------------------------------------
    test('Parse empty rule', () {
      final styles = parseStylesheet('test { }');
      expect(styles.length, 1);
    });

    // -------------------------------------------------------------
    test('Parse single line media query', () {
      final rules =
          parseStylesheet('@media (max-width: 600px) { a { color: red; } }');
      expect(rules.length, 1);
      expect(rules.first, isA<FssMediaRule>());
      expect(
        (rules.first as FssMediaRule).subRules.first.properties.color,
        const Color(0xffff0000),
      );
    });

    // -------------------------------------------------------------
    test('Parse media query with multiple queries', () {
      const input = '''
        @media (min-width: 100px), (max-width: 200px) {
          a { color: red; }
        }
      ''';
      final rules = parseStylesheet(input);
      expect(rules.length, 2);
      expect(rules.first, isA<FssMediaRule>());
      expect(rules.last, isA<FssMediaRule>());
    });

    // -------------------------------------------------------------
    test('Unknown property is skipped in lenient mode', () {
      final warnings = <String>[];
      final styles = parseStylesheet(
        'test { bogus-prop: 1px; color: red; }',
        warnings: warnings,
      );
      expect(styles.length, 1);
      expect(styles.first.properties.color, const Color(0xffff0000));
      expect(warnings, hasLength(1));
      expect(warnings.first, contains('bogus-prop'));
    });

    // -------------------------------------------------------------
    test('Unknown property throws in strict mode', () {
      expect(
        () => parseStylesheet('test { bogus-prop: 1px; }', strict: true),
        throwsA(isA<FssParseException>()),
      );
    });

    // -------------------------------------------------------------
    test('Invalid declaration is skipped in lenient mode', () {
      final warnings = <String>[];
      final styles = parseStylesheet(
        'test { color; color: red; }',
        warnings: warnings,
      );
      expect(styles.first.properties.color, const Color(0xffff0000));
      expect(warnings, hasLength(1));
    });

    // -------------------------------------------------------------
    test('Invalid declaration throws in strict mode', () {
      expect(
        () => parseStylesheet('test { color; }', strict: true),
        throwsA(isA<FssParseException>()),
      );
    });

    // -------------------------------------------------------------
    test('Vendor prefix is stripped', () {
      final styles = parseStylesheet('test { -webkit-text-stroke: 2px blue; }');
      expect(styles.first.properties.textStyle?.foreground?.strokeWidth, 2);
    });

    // -------------------------------------------------------------
    test('Unclosed rule throws', () {
      expect(
        () => parseStylesheet('test { color: red;'),
        throwsA(isA<FssParseException>()),
      );
    });

    // -------------------------------------------------------------
    test('Unbalanced closing bracket throws', () {
      expect(
        () => parseStylesheet('test { color: red; } }'),
        throwsA(isA<FssParseException>()),
      );
    });

    // -------------------------------------------------------------
    test('Unclosed media block throws', () {
      expect(
        () => parseStylesheet('@media (max-width: 600px) { a { color: red; }'),
        throwsA(isA<FssParseException>()),
      );
    });

    // -------------------------------------------------------------
    test('FlutterStyleSheet collects warnings', () {
      final st = FlutterStyleSheet(
        stylesheet: 'test { bogus-prop: 1px; line-height: 11px; }',
      );
      expect(st.rules.length, 1);
      expect(st.parseWarnings, hasLength(1));
      expect(st.rules.first.properties.lineHeight, 11);
    });
  });
}
