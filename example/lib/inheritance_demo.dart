import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

* {
  font-size: 20px;
  color: black;
}

div.mybox {
  color: red;
}

#text2 {
  color: blue;
}

''';

/// Main method of the test application
void main() {
  runApp(const TestApp());
}

/// Creates a simple app with some styleable widgets.
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
      title: 'FSS Inheritance Demo',
      home: _theme ??= FssTheme.withHtmlDefaults(
        stylesheet: styleSheet,
        // This is the "parent" for the text elements
        child: Material(
          color: Colors.white,
          child: Fss<div>(
            clazz: 'mybox',
            c: ListView(
              children: [
                // Center and ListView will be ignored as they are not stylable
                Center(
                  child:
                      Fss<span>(id: 'text1', c: 'Color inherited from parent.'),
                ),
                Fss<span>(id: 'text2', c: 'Color resolved via ID'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
