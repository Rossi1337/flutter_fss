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
class TestApp extends StatelessWidget {
  /// Constructor
  const TestApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSS Div Demo',
      builder: (context, _) => FssTheme.withHtmlDefaults(
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
