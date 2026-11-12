import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheet = '''

* {
  color: fuchsia;  
}

''';

/// Main method of the test application
void main() {
  runApp(const TestApp());
}

/// Creates a simple app with a custom styled widget.
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
      title: 'FSS Custom Demo',
      home: _theme ??= FssTheme.withHtmlDefaults(
        stylesheet: styleSheet,
        child: Material(
          color: Colors.white,
          child: Column(
            children: [
              Fss.styled(
                // Via the FssWidgetBuilder we have access to the styles.
                builder: (context, applicableStyles) {
                  return Text(
                    'Hello World',
                    style: TextStyle(color: applicableStyles.color),
                  );
                },
              ),
              const MyWidget(),
              const MyWidget2(),
            ],
          ),
        ),
      ),
    );
  }
}

/// This example shows you how to access the styles by inheriting from FssWidget
class MyWidget extends FssWidget {
  /// Constructor
  const MyWidget({super.key});

  /// You just need to implement this method where you have access to the styles.
  @override
  Widget buildContent(BuildContext context, FssRuleBlock applicableStyles) {
    return Text(
      'Hello World',
      style: TextStyle(color: applicableStyles.color),
    );
  }
}

/// This widget uses another way to access the styles
/// This can be used anywhere, where you have access to an BuildContext
class MyWidget2 extends StatelessWidget {
  /// Constructor
  const MyWidget2({super.key});

  /// Build method
  @override
  Widget build(BuildContext context) {
    // This gives you access to specially resolved styles.
    final myStyles = resolveApplicableStyles(
      context: context,
      fssType: 'myWidget',
      fssID: 'myID',
      fssClass: 'box darker my_style',
    );

    return Text(
      'Hello World',
      style: TextStyle(color: myStyles.color),
    );
  }
}
