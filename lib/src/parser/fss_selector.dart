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

  /// The selector attribute conditions, e.g. from `[lang]` or `[lang=en]`.
  final List<FssAttributeCondition> attributes;

  /// Constructor to build a selector
  const FssSelector(
    {this.type = '',
    this.id = '',
    this.classes = const [],
    this.attributes = const []});

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

    // Check attribute conditions
    if (attributes.isNotEmpty) {
      final attrs = matchAttributes;
      if (attrs == null) {
        return FssSpecificity.noMatch;
      }
      for (final attr in attributes) {
        if (!attr.matches(attrs)) {
          return FssSpecificity.noMatch;
        }
        classCount++;
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
      listEquals(classes, other.classes) &&
      listEquals(attributes, other.attributes);

  @override
  int get hashCode => Object.hash(type, id, classes, attributes);

  @override
  String toString() =>
      'FssSelector: type="$type" id="$id" classes=$classes'
      '${attributes.isEmpty ? '' : ' attributes=$attributes'}';

  /// Parses a selector string and returns a [FssSelector] object.
  /// The selector string can contain a type, an id and a list of classes.
  factory FssSelector.parse(String selectorPath) {
    // We expect here a single selector. So splitting by "," should to be done already
    var path = selectorPath.trim().toLowerCase();

    // Extract the attribute conditions ([attr], [attr=val], ...) first, so
    // that their syntax (e.g. "~=", "^") is not mistaken for hierarchical
    // selectors and the tokenizer (which splits on "[:.#]") does not break
    // it apart.
    final attrRegExp = RegExp(r'\[([^\[\]]+)\]');
    final List<FssAttributeCondition> attributes = [];
    for (final m in attrRegExp.allMatches(path)) {
      attributes.add(_parseAttributeCondition(m.group(1)!));
    }
    if (attrRegExp.hasMatch(path)) {
      path = path.replaceAll(attrRegExp, '');
    }

    //for example: p h1  or p > h1 or p + h1
    if (path.contains(' ') ||
        path.contains('>') ||
        path.contains('+') ||
        path.contains('~')) {
      throw const FssParseException(
        'Hierarchical selectors are not supported ( + > ~)',
      );
    }
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
      } else if (t.isNotEmpty) {
        type = t;
      }
    }
    return FssSelector(
        type: type, id: id, classes: classes, attributes: attributes);
  }

  /// Parses the inner part of a `[...]` attribute condition, e.g.
  /// `lang`, `lang=en`, `type~=mobile`.
  static FssAttributeCondition _parseAttributeCondition(String spec) {
    final m = RegExp(r'^([\w-]+)\s*(~?=|\*=|\$?=|\|=|\^?=|=)?\s*(.*)$')
        .firstMatch(spec);
    final name = m?.group(1) ?? spec;
    final operator = m?.group(2);
    var value = (m?.group(3) ?? '').trim();
    if (value.length > 1 &&
        (value.startsWith('"') || value.startsWith("'")) &&
        value.endsWith(value[0])) {
      value = value.substring(1, value.length - 1);
    }
    return FssAttributeCondition(
        name: name, operator: operator, value: value.isEmpty ? null : value);
  }
}

/// A single attribute condition of a selector, e.g. from `[lang]` or
/// `[type~=mobile]`.
///
/// [operator] is null for an existence condition (`[lang]`), otherwise one
/// of `=`, `~=`, `^=`, `$=`, `*=` or `|=`.
/// [value] is null for existence conditions and for an empty value, which
/// then matches nothing.
@immutable
class FssAttributeCondition {
  /// Creates a new attribute condition.
  const FssAttributeCondition({required this.name, this.operator, this.value});

  /// The attribute name, e.g. `lang`.
  final String name;

  /// The matching operator, or null for an existence condition.
  final String? operator;

  /// The value to match against, or null for existence conditions.
  final String? value;

  /// Checks if the given element attributes satisfy this condition.
  ///
  /// Both names and values are compared case-insensitively, in line with
  /// the rest of [FssSelector].
  bool matches(Map<String, String> attributes) {
    String? actual;
    for (final entry in attributes.entries) {
      if (entry.key.toLowerCase() == name.toLowerCase()) {
        actual = entry.value;
        break;
      }
    }
    final actualL = actual?.toLowerCase();
    final expectedL = value?.toLowerCase();
    switch (operator) {
      case null:
        return actual != null;
      case '=':
        return expectedL != null && actualL == expectedL;
      case '~=':
        return actualL != null &&
            expectedL != null &&
            actualL.split(RegExp(r'\s+')).contains(expectedL);
      case '^=':
        return actualL != null &&
            expectedL != null &&
            actualL.startsWith(expectedL);
      case r'$=':
        return actualL != null &&
            expectedL != null &&
            actualL.endsWith(expectedL);
      case '*=':
        return actualL != null &&
            expectedL != null &&
            actualL.contains(expectedL);
      case '|=':
        return actualL != null &&
            expectedL != null &&
            (actualL == expectedL || actualL.startsWith('$expectedL-'));
      default:
        return false;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is FssAttributeCondition &&
      name == other.name &&
      operator == other.operator &&
      value == other.value;

  @override
  int get hashCode => Object.hash(name, operator, value);

  @override
  String toString() =>
      'FssAttributeCondition: [$name${operator == null ? '' : '$operator${value ?? ""}'}]';
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
