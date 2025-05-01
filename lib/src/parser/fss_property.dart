import 'package:fss/src/parser/fss_base.dart';
import 'package:fss/src/parser/fss_property_value.dart';
import 'package:fss/src/parser/fss_rule_block.dart';

/// Defines all standard properties with their names and initial values.
///
/// This can be used to lookup properties by name.
/// For example via [FssRuleBlock.get], [FssRuleBlock.getString],
/// [FssRuleBlock.getColor]
enum FssProperty {
  border_top_right_radius._('border-top-right-radius', 'none',
      inherited: false),
  background_color._('background-color', null, inherited: false),
  background_image._('background-image', null, inherited: false),
  background_position._('background-position', 'left top', inherited: false),
  background_repeat._('background-repeat', 'repeat', inherited: false),
  background_size._('background-size', 'auto auto', inherited: false),
  border._('border', null, inherited: false),
  border_bottom._('border-bottom', null, inherited: false),
  border_bottom_color._('border-bottom-color', 'currentcolor',
      inherited: false),
  border_bottom_left_radius._('border-bottom-left-radius', 'none',
      inherited: false),
  border_bottom_right_radius._('border-bottom-right-radius', 'none',
      inherited: false),
  border_bottom_style._('border-bottom-style', 'none', inherited: false),
  border_bottom_width._('border-bottom-width', 'medium', inherited: false),
  border_color._('border-color', null, inherited: false),
  border_left._('border-left', null, inherited: false),
  border_left_color._('border-left-color', 'currentcolor', inherited: false),
  border_left_style._('border-left-style', 'none', inherited: false),
  border_left_width._('border-left-width', 'medium', inherited: false),
  border_radius._('border-radius', null, inherited: false),
  border_right._('border-right', null, inherited: false),
  border_right_color._('border-right-color', 'currentcolor', inherited: false),
  border_right_style._('border-right-style', 'none', inherited: false),
  border_right_width._('border-right-width', 'medium', inherited: false),
  border_style._('border-style', null, inherited: false),
  border_top._('border-top', null, inherited: false),
  border_top_color._('border-top-color', 'currentcolor', inherited: false),
  border_top_left_radius._('border-top-left-radius', 'none', inherited: false),
  accent_color._('accent_color', 'auto'),
  border_top_style._('border-top-style', 'none', inherited: false),
  border_top_width._('border-top-width', 'medium', inherited: false),
  border_width._('border-width', null, inherited: false),
  box_shadow._('box-shadow', 'none', inherited: false),
  caret_color._('caret-color', null),
  color._('color', '#000000'),
  content._('content', 'normal'),
  content_visibility._('content-visibility', 'visible', inherited: false),
  direction._('direction', 'ltr'),
  display._('display', null),
  font._('font', null),
  font_family._('font-family', null),
  font_size._('font-size', 'medium'),
  font_style._('font-style', 'normal'),
  font_weight._('font-weight', 'normal'),
  height._('height', null, inherited: false),
  letter_spacing._('letter-spacing', null),
  line_height._('line-height', null),
  list_style_image._('list-style-image', null),
  list_style_type._('list-style-type', 'disc'),
  margin._('margin', null, inherited: false),
  margin_bottom._('margin-bottom', '0', inherited: false),
  margin_left._('margin-left', '0', inherited: false),
  margin_right._('margin-right', '0', inherited: false),
  margin_top._('margin-top', '0', inherited: false),
  margin_block._('margin-block', null, inherited: false),
  margin_block_start._('margin-block-start', null, inherited: false),
  margin_block_end._('margin-block-end', null, inherited: false),
  margin_inline._('margin-inline', null, inherited: false),
  margin_inline_start._('margin-inline-start', null, inherited: false),
  margin_inline_end._('margin-inline-end', null, inherited: false),
  max_height._('max-height', null, inherited: false),
  max_width._('max-width', null, inherited: false),
  min_height._('min-height', null, inherited: false),
  fss_screen_height._('-fss-screen-height', '${FssBase.dummyScreenHeight}px'),
  overflow._('overflow', 'visible'),
  padding._('padding', null, inherited: false),
  padding_bottom._('padding-bottom', '0', inherited: false),
  padding_left._('padding-left', '0', inherited: false),
  padding_right._('padding-right', '0', inherited: false),
  padding_top._('padding-top', '0', inherited: false),
  text_align._('text-align', 'start'),
  text_decoration._('text-decoration', null, inherited: false),
  text_decoration_color._('text-decoration-color', 'currentcolor',
      inherited: false),
  text_decoration_line._('text-decoration-line', 'none', inherited: false),
  text_decoration_style._('text-decoration-style', 'solid', inherited: false),
  text_decoration_thickness._('text-decoration-thickness', 'none',
      inherited: false),
  text_overflow._('text-overflow', 'clip', inherited: false),
  text_shadow._('text-shadow', 'none'),
  text_stroke._('text-stroke', null, inherited: false),
  text_stroke_color._('text-stroke-color', null, inherited: false),
  text_stroke_width._('text-stroke-width', '0', inherited: false),
  text_transform._('text-transform', 'none'),
  transform._('transform', 'none', inherited: false),
  vertical_align._('vertical-align', 'baseline', inherited: false),
  visibility._('visibility', 'visible'),
  white_space._('white-space', 'normal'),
  width._('width', null, inherited: false),
  word_spacing._('word-spacing', null),
  fss_list_symbol_width._('-fss-list-symbol-width', '3em'),
  fss_list_symbol_gap._('-fss-list-symbol-gap', '0.5em'),
  fss_dashed_pattern._('-fss-dashed-pattern', '8.0 8.0'),
  fss_screen_width._('-fss-screen-width', '${FssBase.dummyScreenWidth}px'),
  min_width._('min-width', null, inherited: false);

  /// Reserved for our own internal properties.
  static const fssPropertyPrefix = '-fss-';

  /// We use this when we split shortcut properties into sub values.
  static const subPropertyPrefix = '_';

  /// Used to declare variables.
  static const varPrefix = '--';

  /// Name of the property
  final String name;

  /// Initial value of the property
  final String? initialValue; // Only null for shorthand properties

  /// If the property is inherited from parent elements.
  final bool inherited;

  /// Private constructor
  const FssProperty._(
    this.name,
    this.initialValue, {
    this.inherited = true,
  });

  /// Gets all property defaults as FssRuleBlock
  static FssRuleBlock getInitialValues() {
    final Map<String, FssPropertyValue> initialProps = {};
    for (final prop in FssProperty.values) {
      if (prop.initialValue != null) {
        initialProps[prop.name] =
            FssPropertyValue(prop.name, prop.initialValue!);
      }
    }
    return FssRuleBlock(initialProps);
  }

  /// Gets a property by its name.
  static FssProperty? byName(String name) =>
      FssProperty.values.where((p) => p.name == name).firstOrNull;
}
