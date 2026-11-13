# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Add the `boundary` key, which makes a boundary by hand, as in `\node[boundary] (B) {};`: a node around the picture so far, unless `fit` says otherwise, with the margins of loose ends as its `inner xsep` and `inner ysep`. On it, `box` gives ports only, without stroke, padding or math. Wires drawn by hand reach it by its name, and a wire from it to itself crosses it. It needs a name.
- Let a call of `\wires` choose its boundary, which is `@` inside the call: `boundary={…}` makes one around the nodes of the call, with these keys, and stays with the call unless its keys name it; `use boundary=B` uses one made before; `boundary=none` uses none, so the picture gets no margins for loose ends. Calls without these keys share the boundary of the picture, as before. An error about the boundary of a call leaves out its loose ends and draws its other wires, and a node wired to a boundary that doesn't hold it gets a warning.

- Add the `box math` key, which sets whether the labels of boxes are in math mode: `box math=false`, on a box, a scope or a picture, gives labels in text, as in `\node[box, box math=false] {whisk};`. Labels are in math mode unless you set it, as before.

- Add the `every box` style, which `box` applies after its own keys: set it to style all the boxes of a picture, a scope or the document, as in `every box/.style={rounded corners, box math=false}`. It doesn't apply to a boundary.

- Add long names for the keys: each one is also under `string diagrams/`, as in `string diagrams/box`, `string diagrams/dot` and `string diagrams/box ports north`. The short names are now styles that call them, and the package itself uses the long names only: if a package or a style of yours takes `dot`, say, `\wires` still works, and `string diagrams/dot` still gives the dot of this package.

### Changed

- **Breaking:** make `@` the boundary of the call inside `\wires`, and nothing outside it: a wire drawn by hand, as in `\draw (f.north) to[wire] (@.north);`, no longer reaches the boundary after a call, and a node of your own named `@` keeps its name outside the calls.
- Require LaTeX 2023-11-01 and expl3 2024-02-20 or later, the versions of TeX Live 2023, in place of LaTeX 2023-06-01 and expl3 2023-06-05: the tests now run on the final TeX Live of 2023, 2024 and 2025, and the older versions were never tested.
- Keep the port counts of boxes in the long names of the `box ports` keys: `\pgfkeysvalueof{/pgf/box ports north}` no longer gives a count, and `\pgfkeysvalueof{/tikz/string diagrams/box ports north}` does. Setting the keys works as before.
- Make the margins of the boundary paddings, as on TikZ's own frame around a picture, so that they no longer scale with the picture: in a scaled picture, loose ends keep their length.
- **Breaking:** put the `box ports` keys under `/tikz/`, as all the other keys, in place of `/pgf/`: in the keys of a picture or a node they work as before, but `\pgfset{box ports=…}` and the full path `/pgf/box ports` no longer find them.
- **Breaking:** name the shape of a box `string diagrams box`, in place of `box`, so that it can't collide with a shape of another package: the `box` key works as before, and `shape=box` no longer gives a box. The macros that a box saves its port counts in have internal names too, in place of `\portsnorth` and the like.
- Open the manual with what the package does and a first diagram, before the keys of boxes.
- List what the package doesn't handle in a section of the manual of its own, "Known limitations", apart from the pitfalls of TikZ: rotated and mirrored pictures, wire ends that are shifted or computed, nodes that aren't rectangles around other nodes, wires in a row, feedback loops, nodes drawn late and scaled pictures.
- Shorten the section of the manual on tagged PDF.
- Remove the change history from the manual: this file is the only one.

### Fixed

- Draw wires inside pics, and under the `name prefix` and `name suffix` keys of TikZ, rather than reporting their nodes as missing: node names are now resolved as TikZ resolves them (#18).
- Draw boxes in documents with the tagging of LaTeX on, as with `\DocumentMetadata{tagging=on}`: every box failed there with "Argument of `\__math_grab_dollar_delim:w` has an extra }", since LaTeX collects each formula whole and a box opens and closes the math of its label in two places. The package now tells LaTeX not to collect that formula. The manual has a section on tagged PDF.
- Draw a node that gets the `box` style twice, as in `\node[box, box=1/0/0/0] {f};` or with `every node/.style={box}`: it failed with "Missing $ inserted", since the second `box` forgot the math that the first had opened.
- Let a wire from a corner that points away from the north or south side of the node around it drift along that side, as it did for the east and west sides: `d.south west = @.north` reached the boundary straight above `d`, and now reaches it to the left, the way the wire leaves.
- Keep the label of a box in math mode where it is in math mode already, as in a `matrix of math nodes` of TikZ: the box opened math again, which closed it, and the label came out in text.
- Ignore blank lines among the wires of `\wires`, which gave TeX's "Paragraph ended before \wires was complete".
- Report a coordinate written as a wire end, as in `f.north.1 = (1,2)`, with an error that says what to write: the commas of the list split it, and the errors named a node `2)`.
- Report `\wires` outside a picture with one error of the package, rather than with "Undefined control sequence" from TikZ and errors about missing nodes.
- File the `box` and `dot` styles under `/tikz/` in the manual, where they are defined, rather than under `/pgf/`.
- Stop slowing down the TikZ pictures of a document that loads the package, with or without wires in them: recording an anchor that TikZ resolves now takes the same time however many are recorded already. A picture that refers to 12,800 anchors took 57 s, and now takes 2.8 s, against 2.4 s without the package (#21).
- Draw wires about four times faster: the regular expressions that read anchor names are now matched once for each name, or replaced by string comparisons (#22).

## [0.4.0] - 2026-11-12

Wires can now be written whole, as `a.north = b.south`, with or without anchors, and styled one by one. The new `wire` key draws them on TikZ paths, and new keys place labels at their ends.

### Added

- Add the `wire` key, which draws a `to` path or an `edge` of TikZ as a wire, as in `\draw (f.north) to[wire] (g.south);`, and the `every wire` style that it applies. Keys after it, such as `out`, `in`, `bend left` or `bend right`, override its angles.
- Let `\wires` take wires written whole, as in `a.north = b.south`, and group them by any beginning they share: after the node they start from, as before, at the `=`, as in `a.north = { b.south, c.south }`, or after the node of their target, as in `a.north = { b = { south.1, south.2 } }`.
- Let keys in brackets begin any entry, group, wire or target of `\wires`, as in `a.north = [dashed] b.south`: they add up from the keys of the call down to each wire, and the closest win.
- Let wire ends leave out their anchor, as in `f = g`, `f.north.1 = g` or `\draw (f) to[wire] (g);`: a bare end is the side that the wire crosses going straight on, or the only port of that side. With one end anchored, the wire leaves or enters as that end says; with both ends bare, it follows the `wire flow`, if set, else the axis that separates the two nodes more. Loose ends need no anchors either, as in `@ = f`. With a flow, a bare wire from a node to itself loops round it, as `f = f`, and one from the boundary to itself crosses the picture, as `@ = @`.
- Add the `wire flow` key, which sets the direction of the wires between bare ends: `north`, `east`, `south` or `west`, or their synonyms `up`, `right`, `down` and `left`, as for the `grow` key of TikZ, or `none`.
- Load the `quotes` library of TikZ, so wires take labels written as quotes, as in `a.north = ["$A$"] b.south`. With a language of babel that makes `"` a shorthand, load the `babel` library of TikZ too.
- Add the `beyond` and `beside` keys, which place labels as the `auto` key of TikZ does, and with its `swap`, but past the end of a wire, as in `"$A$" beyond end` for a loose end, or beside it and clear of the box, as in `"$A$" beside start` for a port. In the `label` of a node, they place the label of a port, as in `label={[beside]north.1:$A$}`. The keys `beyond end`, `beyond start`, `beside end` and `beside start` add the position, as `at end` and `at start` do.
- Add the project site, https://paolobrasolin.github.io/string-diagrams/, where examples compile in the browser and open in Overleaf, with an `llms.txt` that sums up the package for AI assistants.

### Changed

- **Breaking:** draw the wires of `\wires` with the `wire` key, so the `every wire` style applies to them, while the `every to` and `every edge` styles of the picture don't: style them with `every wire` instead of `every to`.
- Turn an end of a wire inwards when its node holds the node of the other end, as the boundary `@` holds the picture, so a frame drawn by hand around a box is wired as the boundary is. Ends on nodes that overlap otherwise face out, and a bare end on them is an error. A node drawn after the first `\wires` of a picture that sticks out of the boundary overlaps it, so its wires to `@` now face out.
- Rewrite the manual in plainer English, and document all of the above, with a section on the pitfalls of TikZ in diagrams.
- Point the home page of the package on CTAN to the project site.
- Require LaTeX 2023-06-01 or later.

### Fixed

- Report a wire to a node that doesn't exist with one error, rather than three, and without drawing a stray curve to the origin.
- Report a wire end at an anchor that its node doesn't have, such as `@.north.1` or a port beyond the count of a box, with one error of the package, rather than an error of PGF about an unknown function `north`, and without drawing a stray curve. `\wires` checks the start of each wire too, and so reports a start on a node that doesn't exist itself.
- Leave out the labels of a wire that isn't drawn, rather than placing them at its start.
- Say in the manual how to load the package, and that it loads TikZ and its libraries, so that its examples compile as they are (#12).
- Fix an undefined command in the implementation notes of the manual (thanks to @quark67).

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

[unreleased]: https://github.com/paolobrasolin/string-diagrams/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/paolobrasolin/string-diagrams/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/paolobrasolin/string-diagrams/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/paolobrasolin/string-diagrams/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/paolobrasolin/string-diagrams/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/paolobrasolin/string-diagrams/releases/tag/v0.1.0
