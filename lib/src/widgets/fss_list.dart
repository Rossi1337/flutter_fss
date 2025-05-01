import 'package:flutter/material.dart';
import 'package:fss/fss.dart';

/// A container that will layout its children in a list (column)
///
/// This mimics to some degree the HTML ul and ol elements
/// Use it in combination with [FssListItem] elements as children.
/// Do not use this class directly. It is cleaner to use Fss.ul and Fss.ol
/// factory methods instead.
///
class FssList extends StatelessWidget {
  const FssList({
    super.key,
    required this.children,
    this.fssType = 'ul',
    this.fssID,
    this.fssClass,
    this.fssAttributes = const {},
  });

  /// FSS class names used to resolve the styles for this container.
  ///
  /// See [FssTheme.resolveStyles] for details how styles are resolved.
  final String? fssClass;

  /// An style ID that can be used to resolve rules from the style sheet.
  final String? fssID;

  /// This specifies the type of the widget that can be used to resolve rules
  /// from the style sheet.
  final String? fssType;

  final Map<String, String>? fssAttributes;

  /// The list items to be displayed.
  /// Can be either [FssListItem] widgets or any other widget that will be
  /// automatically wrapped in a [FssListItem].
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final listItems = _prepareListItems();
    return Fss.block(
      id: fssID,
      fssType: fssType,
      clazz: fssClass,
      builder: (cnx, al) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: listItems,
      ),
    );
  }

  List<Widget> _prepareListItems() {
    int i = 1;
    return children.map((li) {
      if (li is FssListItem) {
        return li._copyWithPos(
          key: ValueKey('$i'),
          listPos: i++,
          listLength: children.length,
        );
      }
      return FssListItem(
        key: ValueKey('$i'),
        listPos: i++,
        listLength: children.length,
        child: li,
      );
    }).toList();
  }
}

/// A list item wrapper
///
class FssListItem extends FssWidget {
  final int listPos;
  final int listLength;

  const FssListItem({
    super.key,
    super.fssType,
    super.fssID,
    super.fssClass,
    super.fssAttributes,
    this.listPos = 1,
    this.listLength = 1,
    required super.child,
  });

  /// Copies this list item and applies a new position or list length
  FssListItem _copyWithPos({
    Key? key,
    required int listPos,
    required int listLength,
  }) =>
      FssListItem(
        key: key,
        fssType: fssType,
        fssID: fssID,
        fssClass: fssClass,
        listLength: listLength,
        listPos: listPos,
        child: child,
      );

  @override
  Widget buildContent(BuildContext context, FssRuleBlock applicableRule) {
    if (!applicableRule.contentVisible) {
      return const SizedBox.shrink();
    }

    Widget symbolWidget;
    final img = applicableRule.getListStyleImage();
    if (img != null) {
      symbolWidget = Image(
        image: img,
        fit: BoxFit.scaleDown,
        height: applicableRule.convert('1em'),
      );
    } else {
      final symbol = applicableRule.getListStyleSymbol(listPos, listLength);
      // What a shame but the Noto font does not contain these as characters!
      // So we use here a hack with icons
      final s = applicableRule.convert('0.5em');
      final c = applicableRule.color;
      symbolWidget = switch (symbol) {
        'disc' => Icon(Icons.fiber_manual_record, color: c, size: s),
        'circle' => Icon(Icons.fiber_manual_record_outlined, color: c, size: s),
        'square' => Icon(Icons.stop, color: c, size: s),
        _ => Fss.span(symbol),
      };
    }

    final symbolInset = applicableRule.getSize('-fss-list-symbol-width') ??
        applicableRule.convert('3em');
    final symbolPadding = applicableRule.getSize('-fss-list-symbol-gap') ??
        applicableRule.convert('0.5em');

    return Row(
      children: [
        Padding(
          padding: EdgeInsets.only(right: symbolPadding),
          child: Container(
            constraints: BoxConstraints(minWidth: symbolInset),
            alignment: AlignmentDirectional.centerEnd,
            child: symbolWidget,
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}
