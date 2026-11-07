import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fss/fss.dart';

void main() {
  testWidgets(
      'FssTheme does not rebuild descendants when the same stylesheet '
      'instance is reused', (tester) async {
    var builds = 0;
    FssTheme makeTheme(FlutterStyleSheet stylesheet) => FssTheme.fromStylesheet(
          stylesheet: stylesheet,
          child: Builder(
            builder: (context) {
              builds++;
              return const SizedBox();
            },
          ),
        );

    final theme = makeTheme(
      FlutterStyleSheet(stylesheet: 'test { color: red; }'),
    );

    await tester.pumpWidget(MaterialApp(home: theme));
    final initialBuilds = builds;
    expect(initialBuilds, 1);

    // The same FssTheme widget (and stylesheet instance) again.
    // Nothing in the subtree should rebuild.
    await tester.pumpWidget(MaterialApp(home: theme));
    expect(builds, initialBuilds);

    // A different stylesheet instance invalidates the subtree.
    final other = makeTheme(
      FlutterStyleSheet(stylesheet: 'test { color: blue; }'),
    );
    await tester.pumpWidget(MaterialApp(home: other));
    expect(builds, initialBuilds + 1);
  });
}
