import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

const styleSheetFile = 'assets/test_app.fss';

/// Main method of the test application
void main() {
  runApp(const TestApp());
}

/// Simple example application that loads a stylesheet from a file in the
/// assets and then install it as a theme into the widget tree.
class TestApp extends StatelessWidget {
  /// Constructor
  const TestApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FSS Demo App',
      // Here we inject the FSS theme into the widget tree
      // We use the system Theme to set some default styles and rules.
      // This will take over the color theme and fonts of the system.
      // We use a future builder because we load the stylesheet from an asset.
      builder: (context, _) => FutureBuilder(
        future: DefaultAssetBundle.of(context).loadString(styleSheetFile),
        builder: (context, stylesheetAsset) {
          if (!stylesheetAsset.hasData) {
            return const CircularProgressIndicator();
          }

          return FssTheme.withAppDefaults(
            context: context,
            stylesheet: stylesheetAsset.data.toString(),
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
      ),
    );
  }
}
