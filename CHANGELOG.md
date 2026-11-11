# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Add the `wire` key, which draws a `to` path or an `edge` of TikZ as a wire, as in `\draw (f.north) to[wire] (g.south);`, and the `every wire` style that it applies.

### Changed

- Require LaTeX 2023-06-01 or later.

## [0.3.0] - 2026-11-07

Loose ends are now ordinary wires to the boundary of the picture, a node called `@`, so they run straight out to the side they are wired to, or bend towards it. Wires also leave the corners of nodes diagonally and can fan out from an anchor, boxes take their port counts from the picture or scope around them, and mistakes in wire ends and port counts are reported with clear errors. This release also fixes several long-standing bugs, found by a new regression test suite run on pdfTeX, XeTeX and LuaTeX.

### Added

- Add the boundary node `@`, which `\wires` draws around the picture: wires to its sides are the loose ends of a diagram.

### Changed

- Keep the port counts in force, such as those set on a scope, when `box` is given none, rather than resetting them to none. Every box starts with no ports, including the bare `box` shape, which had one per side.
- Make wires leave corners such as `north east` diagonally, rather than like the side named first.
- Report wire ends without an anchor, such as `b` instead of `b.south`, with an error.
- Require expl3 2023-06-05 or later.

### Removed

- **Breaking:** remove the third argument of `\wires`, which listed loose ends: draw them as wires to the boundary instead, as in `f = { south = @.south }` for `f.south`. A third argument is no longer read.

### Fixed

- Report ports a box doesn't have with an error naming the box, rather than placing them outside it or dividing by zero.
- Report wire ends that aren't on a side with an error, rather than drawing a stray curve.
- Report port counts that aren't four, such as `box=2`, with an error, rather than a runaway argument or a silently wrong count.
- Draw every wire listed in `\wires`, including those of a node listed twice or an anchor listed twice, rather than only the last one.

## [0.2.1] - 2023-06-13

### Fixed

- Avoid crashing when optional `\wires` parameter is not given.

## [0.2.0] - 2023-06-12

### Added

- Make box ports count configurable.

## [0.1.0] - 2023-05-31

### Added

- Initial version.

[unreleased]: https://github.com/paolobrasolin/string-diagrams/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/paolobrasolin/string-diagrams/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/paolobrasolin/string-diagrams/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/paolobrasolin/string-diagrams/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/paolobrasolin/string-diagrams/releases/tag/v0.1.0
