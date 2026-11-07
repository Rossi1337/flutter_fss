## 2.0.0-alpha1

Complete internal restructuring. Adding support for more CSS attributes and fixing many issues.

* Reimplemented the stylesheet parser as a character based tokenizer.
  Any layout is now supported: multi line pretty styles as well as
  minified single line files. Declarations no longer need to be
  one per line and values containing ":" (like `url(http://...)`)
  work correctly. `!important` flags and vendor prefixes like
  `-webkit-` are tolerated.
* The parser is more robust. Unknown properties, invalid declarations
  and unsupported selectors are no longer fatal by default. They are
  skipped and reported via the new `parseWarnings` list of
  `FlutterStyleSheet` (or the `warnings` parameter of `parseStylesheet`).
  Pass `strict: true` to get the legacy throwing behaviour back.
  Structural errors like unbalanced brackets are always reported and
  now carry line and column information.

## 1.0.0

* Added support for vw, vh, vmin, vmax sizing
* More docu
* More tests
* Minor code cleanup
* Bumped version to 1.0 

## 0.1.1

* Added example for pub.dev
* Fixed some small issues when resolving by ID with different case.  

## 0.1.0

* Initial version. Covers already many features of CSS and is ready to be used.  

