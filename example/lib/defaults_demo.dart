import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

#bg {
  background-color: black;
  padding: 10px;
} 

body {
  font-size: 14px;
  color: FloralWhite;
}

''';

/// Main method of the test application
void main() {
  runApp(const TestApp());
}

/// Creates a simple app that displays the default property values,
/// variables and rules.
///
/// We add a lot of the standard material theme values as variables
/// with the --mat prefix. You can use them in your own rules via the var()
/// function.
///
class TestApp extends StatelessWidget {
  /// Constructor
  const TestApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSS Defaults Demo',
      builder: (context, _) => FssTheme.withHtmlDefaults(
        stylesheet: styleSheet,
        child: Builder(
          builder: (context) {
            final theme = FssTheme.of(context)!;
            // This gives you all the details of the currently used fss theme
            final dump = theme.toString(minLevel: DiagnosticLevel.fine);
            return Fss<div>(
              id: 'bg',
              c: SingleChildScrollView(child: Fss<body>(c: dump)),
            );
          },
        ),
      ),
    );
  }
}
