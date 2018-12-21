# The Last API Wrapper Changelog

## 0.1.0.pre (2018-12-21)

* `Namespace#children` is an `Array` now, with `Namespace#child_index` being a `Hash` (@marcandre);
* DSL now can accept strings as a Namespace/Endpoint name (@marcandre);
* Classes' `.inspect` fixed to match Ruby's conventions (@marcandre);
* Improved object tree navigation (@marcandre):
  * `APIPath#parent`, `APIPath.parent` (immediate parent class/object);
  * `APIPath#parents`, `APIPath.parents` (parent classes/objects all the way up);
  * `Namespace#traverse` (depth-first children tree enumeration).
* Lots of refactoring (better call it "rewrite", honestly), internal structure was simplified and
  decoupled, API and DSL was kept the same (I hope).
  * I am really thankful to @marcandre and @joelvh for cleaning up job they've done. Sorry, guys,
    eventually I've rewrote the thing completely :)
* Added `shared_def`/`use_def` to reuse some common parts of definitions (thanks @marcandre for
  discussion).

## 0.0.2 (2017-07-31)

* Codebase modernized and rubocopped;
* Support for redirects;
* Support for pattern-based (regexp) postprocessors.

## 0.0.1 (2016-09-19)

Initial release.
