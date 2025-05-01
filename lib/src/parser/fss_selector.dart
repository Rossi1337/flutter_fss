import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fss/src/exception/fss_parse_exception.dart';

/// Defines a selector based on a "type" an "id" and a list of "classes"
///
/// There is a special selector with type=* that will match all elements.
@immutable
class FssSelector {
  /// The selector type that matches all types.
  static const typeAll = '*';

  /// The selector that matches all types.
  static const matchAll = FssSelector(type: typeAll);

  /// The selector type.
  final String type;

  /// The selector id.
  final String id;

  /// The selector classes.
  final List<String> classes;

  /// Constructor to build a selector
  const FssSelector({this.type = '', this.id = '', this.classes = const []});

  /// Checks if the given type, id and classes will be matched by this selector.
  ///
  /// Returns the specificity of the selector matching the input with
  /// 0 meaning no match.
  /// The bigger the number the better is the match of this selector.
  /// Type match adds 1, class match adds 1000, id match adds 1million.
  FssSpecificity getSpecificity(
    String? matchType,
    String? matchId,
    List<String>? matchClasses, [
    MediaQueryData? media,
    Map<String, String>? matchAttributes,
  ]) {
    // Check type
    int typeCount = 0;
    final matchTypeL = matchType?.toLowerCase();
    if (type == typeAll) {
      typeCount++;
    } else if (type.isNotEmpty && type != matchTypeL) {
      return FssSpecificity.noMatch;
    } else if (type.isNotEmpty && type == matchTypeL) {
      typeCount++;
    }

    // Check classes
    if (classes.isNotEmpty && (matchClasses == null || matchClasses.isEmpty)) {
      return FssSpecificity.noMatch;
    }
    final matchClassesL = [];
    matchClasses?.forEach((cl) => matchClassesL.add(cl.toLowerCase()));
    for (final cl in classes) {
      if (!matchClassesL.contains(cl)) {
        return FssSpecificity.noMatch;
      }
    }
    int classCount = classes.length;

    // Check ID
    int idCount = 0;
    final matchIdL = matchId?.toLowerCase();
    if (id.isNotEmpty && id != matchIdL) {
      return FssSpecificity.noMatch;
    } else if (id.isNotEmpty && id == matchIdL) {
      idCount++;
    }

    // Check attributes
    if (matchAttributes != null && matchAttributes.isNotEmpty) {
      for (final entry in matchAttributes.entries) {
        final attributeName = entry.key.toLowerCase();
        final attributeValue = entry.value.toLowerCase();

        // If the selector has an attribute condition, check it
        if (classes.contains('[$attributeName=$attributeValue]') ||
            classes.contains('[$attributeName]')) {
          classCount++;
        } else {
          return FssSpecificity.noMatch;
        }
      }
    }

    return FssSpecificity(
      ids: idCount,
      classes: classCount,
      types: typeCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FssSelector &&
      id == other.id &&
      type == other.type &&
      listEquals(classes, other.classes);

  @override
  int get hashCode => Object.hash(type, id, classes);

  @override
  String toString() => 'FssSelector: type="$type" id="$id" classes=$classes';

  /// Parses a selector string and returns a [FssSelector] object.
  /// The selector string can contain a type, an id and a list of classes.
  factory FssSelector.parse(String path) {
    // We expect here a single selector. So splitting by "," should to be done already
    path = path.trim().toLowerCase();

    //for example: p h1  or p > h1 or p + h1
    if (path.contains(' ') ||
        path.contains('>') ||
        path.contains('+') ||
        path.contains('~')) {
      throw const FssParseException(
        'Hierarchical selectors are not supported ( + > ~)',
      );
    }
    //for example: [target]
    // if (path.contains('[') && path.contains(']')) {
    //   throw const FssParseException(
    //     'Attribute matching selectors are not supported [...]',
    //   );
    // }

    //for example: p::before
    if (path.contains('::')) {
      throw const FssParseException(
        'Selectors for virtual elements are not supported (::before ::after)',
      );
    }

    String type = '';
    String id = '';
    final List<String> classes = [];
    final token = path.split(RegExp(r'(?=[\.:#])'));
    for (final t in token) {
      if (t.startsWith('.') || t.startsWith(':')) {
        classes.add(t);
      } else if (t.startsWith('#')) {
        id = t;
      } else {
        type = t;
      }
    }
    return FssSelector(type: type, id: id, classes: classes);
  }
}

/// A class to hold the specificity of a selector.
/// It is used to compare the specificity of two selectors.
@immutable
class FssSpecificity implements Comparable<FssSpecificity> {
  static const noMatch = FssSpecificity();

  final int ids;
  final int classes;
  final int types;

  /// Constructor to build a specificity object
  const FssSpecificity({
    this.ids = 0,
    this.classes = 0,
    this.types = 0,
  });

  @override
  bool operator ==(Object other) =>
      other is FssSpecificity &&
      ids == other.ids &&
      classes == other.classes &&
      types == other.types;

  bool operator >(FssSpecificity other) => compareTo(other) > 0;
  bool operator <(FssSpecificity other) => compareTo(other) < 0;
  bool operator >=(FssSpecificity other) => compareTo(other) >= 0;
  bool operator <=(FssSpecificity other) => compareTo(other) <= 0;

  @override
  int get hashCode => Object.hash(ids, classes, types);

  @override
  String toString() => 'FssSpecificity: ids=$ids classes=$classes types=$types';

  /// Compares the specificity of two selectors.
  @override
  int compareTo(FssSpecificity other) {
    if (ids != other.ids) {
      return ids.compareTo(other.ids);
    } else if (classes != other.classes) {
      return classes.compareTo(other.classes);
    } else {
      return types.compareTo(other.types);
    }
  }
}
