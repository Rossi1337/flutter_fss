import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

* {
  font-size: 20px;
}

#text1 {
  font-size: 32px;
  color: red;
}

#text2 {
  font-weight: bold;
}

#text3 {
  font-style: italic;
}

#text4 {
  text-decoration-line: underline;
  text-decoration-style: dashed;
}

#text5 {
  text-decoration-line: line-through;
}

#text6 {
  text-transform: uppercase;
}

#text7 {
  text-shadow: 3 3 1.5 gray;
}

#text8 {
  color: brown; 
  font-size: 40px;
  font-style: italic;
  font-family: StyleScript; 
  text-shadow: 3 3 1.5 gray;
  text-decoration-line: underline;
  text-decoration-style: dotted;
}

#text9 {
  content: Text replaced via CSS "content";
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
      title: 'FSS Text Demo',
      builder: (context, _) => FssTheme.withHtmlDefaults(
        stylesheet: styleSheet,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: [
              Fss<span>(
                id: 'text1',
                c: 'Size 32, Red: Almost before we knew it, we had left the ground.',
              ),
              Fss<span>(
                id: 'text2',
                c: 'Bold: Almost before we knew it, we had left the ground.',
              ),
              Fss<span>(
                id: 'text3',
                c: 'Italic: Almost before we knew it, we had left the ground.',
              ),
              Fss<span>(
                id: 'text4',
                c: 'Underline dashed: Almost before we knew it, we had left the ground.',
              ),
              Fss<span>(
                id: 'text5',
                c: 'Line through: Almost before we knew it, we had left the ground.',
              ),
              Fss<span>(
                id: 'text6',
                c: 'Uppercase:  Almost before we knew it, we had left the ground.',
              ),
              Fss<span>(
                id: 'text7',
                c: 'Shadow: Almost before we knew it, we had left the ground.',
              ),
              Fss<span>(
                id: 'text8',
                c: 'Custom font: Almost before we knew it, we had left the ground.',
              ),
              Fss<span>(
                id: 'text9',
                c: 'Text replacement: Almost before we knew it, we had left the ground.',
              ),
              Fss<h1>(c: 'Using default html tags'),
              Fss<i>(c: '<i>Text by using tag</i>'),
              Fss<b>(c: '<b>Text by using tag</b>'),
              Fss<s>(c: '<s>Text by using tag</s>'),
              Fss<u>(c: '<u>Text  by using tag</u>'),
            ],
          ),
        ),
      ),
    );
  }
}
