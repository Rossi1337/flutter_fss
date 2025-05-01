import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

/// The stylesheet should normally be an own assets file
/// It is defined here inline for the example
const styleSheet = '''
.box {
  width: 200px;
  height: 50px;
  text-align: center; 
  margin: 5px;
  background-image: linear-gradient(180deg, #111174, #3d72b4);
  border-radius: 10px;
  box-shadow: 3 3 1.5 0.5 gray;  
}

#myText {   
  color: white;
  font-size: 32px;  
}
''';

/// Entry point
void main() {
  runApp(const TestApp());
}

/// Creates a simple app
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSS Simple Demo',
      // Install the theme with the given stylesheet
      builder: (context, _) => FssTheme.withHtmlDefaults(
        stylesheet: styleSheet,
        // Add a div with a given "class" and a text with a given "id"
        child: Center(
          child: Fss<div>(
            clazz: 'box',
            c: Fss<span>(id: 'myText', c: 'Hello World'),
          ),
        ),
      ),
    );
  }
}
