import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

ul.custom {
  color: red;
  list-style-type: #;
}

ul.square {
  color: green;
  list-style-type: square;
}

ol.decimal {
  color: brown;
  list-style-type: decimal;
}

ol.roman {
  color: purple;
  list-style-type: lower-roman;
}

ol.spacing {
  color: purple;
  list-style-type: upper-latin;
  -fss-list-symbol-width: 20px;
  -fss-list-symbol-gap: 30px;
}


''';

/// Main method of the test application
void main() {
  runApp(const TestApp());
}

/// Creates a simple app with a single list.
/// So you get the styles of the STYLESHEET above.
class TestApp extends StatefulWidget {
  /// Constructor
  const TestApp({super.key});

  @override
  State<TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  // The theme is created once on the first build. Reusing the same instance
  // on every rebuild avoids re-parsing the stylesheet.
  FssTheme? _theme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSS List Demo',
      builder: (context, _) => _theme ??= FssTheme.withHtmlDefaults(
        stylesheet: styleSheet,
        child: ListView(
          children: [
            Fss.ul(
              children: [
                Fss<span>(c: 'With default icon'),
                Fss<span>(c: 'Second'),
                Fss<span>(c: 'Third'),
              ],
            ),
            Fss.ul(
              clazz: 'custom',
              children: [
                Fss<span>(c: 'With custom text'),
                Fss<span>(c: 'Second'),
                Fss<span>(c: 'Third'),
              ],
            ),
            Fss.ul(
              clazz: 'square',
              children: [
                Fss<span>(c: 'With square icon'),
                Fss<span>(c: 'Second'),
                Fss<span>(c: 'Third'),
              ],
            ),
            Fss.ol(
              clazz: 'decimal',
              children: [
                Fss<span>(c: 'With number'),
                Fss<span>(c: 'Second'),
                Fss<span>(c: 'Third'),
              ],
            ),
            Fss.ol(
              clazz: 'roman',
              children: [
                Fss<span>(c: 'With roman numbers'),
                Fss<span>(c: 'Second'),
                Fss<span>(c: 'Third'),
              ],
            ),
            Fss.ol(
              clazz: 'spacing',
              children: [
                Fss<span>(c: 'With custom spacing'),
                Fss<span>(c: 'Second'),
                Fss<span>(c: 'Third'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
