import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

* {
  font-size: 20px;
}

div {
  background-color: lightblue;
}

div.ex1 {
  border: 1px solid black;
  margin-block: 50px 25px;
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
      title: 'FSS Div Demo',
      builder: (context, _) => _theme ??= FssTheme.withHtmlDefaults(
        stylesheet: styleSheet,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Fss<div>(c: 'A div element with no specified margins.'),
              Fss<div>(c: 'A div element with no specified margins.'),
              Fss<div>(c: 'A div element with no specified margins.'),
              Fss<div>(
                clazz: 'ex1',
                c: 'A div element with no specified margins.',
              ),
              Fss<div>(c: 'A div element with no specified margins.'),
            ],
          ),
        ),
      ),
    );
  }
}
