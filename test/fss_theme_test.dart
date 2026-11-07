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

  testWidgets(
      'FssParent does not rebuild unchanged descendants when resolved styles '
      'are value-equal', (tester) async {
    var innerBuilds = 0;

    final stylesheet = FlutterStyleSheet(stylesheet: '.box { color: red; }');
    final changedStylesheet = FlutterStyleSheet(
      stylesheet: '.box { color: blue; }',
    );

    await tester.pumpWidget(_ParentAmplificationHarness(
      stylesheet: stylesheet,
      onInnerBuild: () => innerBuilds++,
    ));
    // The initial frame may build the inner tree more than once (inherited
    // dependencies registered during the same frame are flushed in the same
    // pass). Only the deltas below are what this test cares about.
    final initial = innerBuilds;
    expect(initial, greaterThan(0));

    // Unrelated state change: the outer Fss widget is recreated, but the
    // resolved styles are value-equal and the inner tree consists of stable
    // widget instances. Nothing inside should rebuild.
    final state = tester.state<_ParentAmplificationState>(
      find.byType(_ParentAmplificationHarness),
    );
    state.updateLabel('B');
    await tester.pump();
    expect(innerBuilds, initial);

    // A real stylesheet change still rebuilds the subtree.
    await tester.pumpWidget(_ParentAmplificationHarness(
      stylesheet: changedStylesheet,
      onInnerBuild: () => innerBuilds++,
    ));
    expect(innerBuilds, initial + 1);
  });
}

/// A stateful root that contains an outer [Fss.div] (recreated on every
/// build) wrapping a stable inner [Fss.div] tree. Every build of the inner
/// tree invokes [onInnerBuild].
class _ParentAmplificationHarness extends StatefulWidget {
  const _ParentAmplificationHarness({
    required this.stylesheet,
    required this.onInnerBuild,
  });

  final FlutterStyleSheet stylesheet;
  final VoidCallback onInnerBuild;

  @override
  State<_ParentAmplificationHarness> createState() =>
      _ParentAmplificationState();
}

class _ParentAmplificationState extends State<_ParentAmplificationHarness> {
  String _label = 'A';

  /// Simulates an unrelated state change that rebuilds the subtree.
  void updateLabel(String label) => setState(() => _label = label);

  late final Widget _inner = Fss.div(
    clazz: 'box',
    builder: (context, styles) {
      widget.onInnerBuild();
      return const SizedBox(width: 20, height: 20);
    },
  );

  @override
  Widget build(BuildContext context) {
    return FssTheme.fromStylesheet(
      stylesheet: widget.stylesheet,
      child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_label),
              Fss.div(clazz: 'box', child: _inner),
            ],
          )),
    );
  }
}
