import 'package:flutter/material.dart';
import 'package:fss/src/parser/fss_rule_block.dart';

/// Widget builder callback that gives you access to the "applicable properties".
typedef FssWidgetBuilder = Widget Function(
  BuildContext context,
  FssRuleBlock applicableRule,
);
