import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fss/fss.dart';

const styleSheetFile = 'assets/test_app.fss';

/// Main method of the test application
void main() {
  runApp(const TestApp());
}

/// Simple example application that loads a stylesheet from a file in the
/// assets and then install it as a theme into the widget tree.
class TestApp extends StatefulWidget {
  /// Constructor
  const TestApp({super.key});

  @override
  State<TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  // The stylesheet content, loaded from the asset once.
  String? _stylesheet;

  // The theme is created once when the stylesheet arrives and the same
  // widget instance is returned on every rebuild. This way the stylesheet
  // is parsed only once and the resolved styles stay alive.
  FssTheme? _theme;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString(styleSheetFile).then((data) {
      if (mounted) {
        setState(() => _stylesheet = data);
      }
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSS Demo App',
      // Here we inject the FSS theme into the widget tree
      // We use the system Theme to set some default styles and rules.
      // This will take over the color theme and fonts of the system.
      builder: (context, _) {
        final stylesheet = _stylesheet;
        if (stylesheet == null) {
          return const CircularProgressIndicator();
        }

        return _theme ??= FssTheme.withAppDefaults(
          context: context,
          stylesheet: stylesheet,
          // Now we add the widgets of the demo app. A div container and
          // inside some example widgets.
          child: Fss.div(
            clazz: 'frame',
            builder: (context, ap) => SingleChildScrollView(
              child: Column(
                children: [
                  // Lets add some text with different styles
                  Fss<h1>(c: 'H1 - FSS'),
                  Fss<h2>(c: 'H2 - FSS with style.'),
                  Fss<h3>(c: 'H3 - FSS style your widgets with style.'),
                  Fss<h4>(c: 'H4 - FSS style your widgets with style.'),
                  Fss<h5>(c: 'H5 - FSS style your widgets with style.'),
                  Fss<h6>(c: 'H6 - FSS style your widgets with style.'),
                  Fss<subtitle1>(
                      c: 'Subtitle1 - FSS style your widgets with style.'),
                  Fss<subtitle2>(
                      c: 'Subtitle1 - FSS style your widgets with style.'),
                  Fss<body>(c: 'Body - FSS style your widgets with style.'),
                  Fss<body2>(c: 'Body2 - FSS style your widgets with style.'),
                  Fss<caption>(
                      c: 'Caption - FSS style your widgets with style.'),
                  Fss.hr(),
                  // We also offer a simple list
                  Fss.ol(
                    clazz: 'simple',
                    children: [
                      Fss.span('A simple styleable list'),
                      Fss.span('Second'),
                      Fss.span('Third'),
                    ],
                  ),
                  // Here we use a button and configure it from styles.
                  // For this we lookup the styles for the element type "button"
                  Fss.styled(
                    fssType: 'button',
                    builder: (context, styles) => ElevatedButton(
                      onPressed: () => {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: styles.backgroundColor,
                        foregroundColor: styles.color,
                      ),
                      child: Text('My Button', style: styles.textStyle),
                    ),
                  ),

                  // Finally we add an image. It has the fss class "test"
                  Fss.img(id: 'my_img', src: const AssetImage('test.png')),

                  // Screen size proportional sizes
                  Fss.styled(
                    id: 'screen_info',
                    builder: (context, styles) => Fss<span>(
                      c: 'Size vw/vh: ${styles.getSize(FssProperty.max_width.name)} x '
                          '${styles.getSize(FssProperty.max_height.name)}'
                          ' -> 50%: ${styles.getSize(FssProperty.min_width.name)} x '
                          '${styles.getSize(FssProperty.min_height.name)}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
