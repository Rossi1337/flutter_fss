import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''
.frame {
  text-align: center;
  margin: 8px;
}
.box {
  width: 150px;
  height: 150px;
  border: 2px solid black;
}
// red is the start colour, so the reddest point marks the "from" angle.
#sw0   { background-image: sweep-gradient(from 0deg, red, blue); }
#sw90  { background-image: sweep-gradient(from 90deg, red, blue); }
#sw180 { background-image: sweep-gradient(from 180deg, red, blue); }
#sw270 { background-image: sweep-gradient(from 270deg, red, blue); }
#swdef { background-image: sweep-gradient(red, blue); }
''';

/// Main method of the test application
void main() {
  runApp(const TestApp());
}

/// Small app to visually verify the sweep-gradient "from" angle.
///
/// The reddest point of each sweep marks the start angle, so it should point
/// to 12/3/6/9 o'clock for `from 0/90/180/270deg` (and 12 o'clock for the
/// default, which is `from 0deg`).
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
      title: 'FSS Sweep Gradient Demo',
      home: _theme ??= FssTheme.withHtmlDefaults(
        stylesheet: styleSheet,
        child: Material(
          color: Colors.white,
          child: Scaffold(
            body: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'sweep-gradient(from <angle>, red, blue)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _row("from 0deg   (12 o'clock)", 'sw0'),
                    _row("from 90deg  (3 o'clock)", 'sw90'),
                    _row("from 180deg (6 o'clock)", 'sw180'),
                    _row("from 270deg (9 o'clock)", 'sw270'),
                    _row('default     (no from)', 'swdef'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String id) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Fss<div>(id: id, clazz: 'box', c: ''),
        const SizedBox(width: 24),
        SizedBox(width: 220, child: Text(label)),
      ],
    );
  }
}
