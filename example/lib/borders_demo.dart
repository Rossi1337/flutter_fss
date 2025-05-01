import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

div {
  text-align: center;
  background-color: yellow;
  color: black;
  margin: 5px;
}

#box1 {
  border: 3px solid black;
}

#box2 {
  border: 3px dashed black;
}

#box3 {
  border: 3px dotted black;
}

#box4 {
  border: 3px hidden black;
}

#box5 {
  border-top: 2px solid black;
}

#box6 {
  border-bottom: 3px dashed blue;
}

#box7 {
  border-left: 4px dotted red;
}

#box8 {
  border-right: 5px solid green;
}

#box9 {
  border-top: 3px solid black;
  border-bottom: 3px solid black;
}

#box10 {
  border-left: 3px solid black;
  border-right: 3px solid black;
}

#box11 {
  border: 3px solid black;
  border-radius: 10px;
}

#box12 {
  border: 3px dashed black;
  border-radius: 10px;
}

#box13 {
  border: 3px dotted black;
  border-radius: 10px;
}

#box14 {
  border: 3px hidden black;
  border-radius: 10px;
}

#box15 {
  border-top: 3px solid red;
  border-right: medium dashed green;
  border-bottom: thick solid blue;
  border-left: 5px dotted gray;
}

#box16 {
  border: medium inset #cccccc;
}

#box17 {
  border: medium outset #cccccc;
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
      title: 'FSS Border Demo',
      builder: (context, _) => FssTheme.withHtmlDefaults(
        stylesheet: styleSheet,
        child: GridView.count(
          crossAxisCount: 5,
          padding: const EdgeInsets.all(8),
          children: [
            Fss<div>(id: 'box1', c: 'solid'),
            Fss<div>(id: 'box2', c: 'dashed'),
            Fss<div>(id: 'box3', c: 'dotted'),
            Fss<div>(id: 'box4', c: 'hidden'),
            Fss<div>(id: 'box5', c: 'top'),
            Fss<div>(id: 'box6', c: 'bottom'),
            Fss<div>(id: 'box7', c: 'left'),
            Fss<div>(id: 'box8', c: 'right'),
            Fss<div>(id: 'box9', c: 'top bottom'),
            Fss<div>(id: 'box10', c: 'left right'),
            Fss<div>(id: 'box11', c: 'radius solid'),
            Fss<div>(id: 'box12', c: 'radius dashed'),
            Fss<div>(id: 'box13', c: 'radius dotted'),
            Fss<div>(id: 'box14', c: 'radius hidden'),
            Fss<div>(id: 'box15', c: 'mixed'),
            Fss<div>(id: 'box16', c: 'inset'),
            Fss<div>(id: 'box17', c: 'outset'),
          ],
        ),
      ),
    );
  }
}
