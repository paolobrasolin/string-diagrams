# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Keep the port counts in force, such as those set on a scope, when `box` is given none, rather than resetting them to none. Every box starts with no ports, including the bare `box` shape, which had one per side.
- Make wires leave corners such as `north east` diagonally, rather than like the side named first.

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

[unreleased]: https://github.com/paolobrasolin/string-diagrams/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/paolobrasolin/string-diagrams/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/paolobrasolin/string-diagrams/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/paolobrasolin/string-diagrams/releases/tag/v0.1.0
