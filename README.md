# string-diagrams

[![CTAN release][ctan-shield]][ctan-link]
[![GitHub release][release-shield]][release-link]
[![Project licence][licence-shield]][licence-link]

[ctan-shield]: https://img.shields.io/ctan/v/string-diagrams?label=CTAN
[ctan-link]: https://ctan.org/pkg/string-diagrams
[release-shield]: https://img.shields.io/github/v/release/paolobrasolin/string-diagrams?display_name=release&include_prereleases
[release-link]: https://github.com/paolobrasolin/string-diagrams/releases/
[licence-shield]: https://img.shields.io/github/license/paolobrasolin/string-diagrams
[licence-link]: https://www.latex-project.org/lppl.txt

Create stunning string diagrams with LaTeX!

`string-diagrams` is a LaTeX package designed for effortless and aesthetically pleasing creation of string diagrams.

## Getting Started

### Prerequisites

The only thing you need is an up-to-date LaTeX distribution including TikZ.

### Installation

The fastest way to hit the ground running is to download `string-diagrams` from CTAN via your package manager. For instance, TeXLive users can run `tlmgr install string-diagrams` or select `string-diagrams` from the GUI.

Alternatively, you can download the package from the [CTAN page](https://www.ctan.org/pkg/string-diagrams), unzip the archive, and place `string-diagrams.sty` in your working directory.

For those who always live on the edge, unreleased versions are available on the [releases page](https://github.com/paolobrasolin/string-diagrams/releases).

### Usage

After including the package in your preamble, you can craft your string diagrams in a `tikzpicture` environment:

```latex
\usepackage{string-diagrams}

%...

\begin{tikzpicture}
  \node[box] (a) {a};
  \node[box] (b) at (0,-2) {b};
  \node[dot] (x) at (1,-1) {};
  \node[dot] (y) at (-1,-1) {};
  \wires[]{
    a = { east = x.north },
    b = { east0 = x.south },
    y = { north = a.west1, south = b.west },
  }{
    a.west0, b.east1, x.east, y.west
  }
\end{tikzpicture}
```

Detailed instructions are available in the [documentation](http://mirrors.ctan.org/graphics/pgf/contrib/string-diagrams/string-diagrams.pdf).

## Contributing

Got a fantastic idea? Noticed a bug? Contributions are more than welcome! Please feel free to share your thoughts via the [issue tracker](https://github.com/paolobrasolin/string-diagrams/issues).

For the adventurous, you can [fork the repository](https://github.com/paolobrasolin/string-diagrams/fork), create some magic, and [submit a pull request](https://github.com/paolobrasolin/string-diagrams/pulls).

## License

This project is licensed under the LPPL-1.3c License.

## Acknowledgements

Special gratitude goes to the [Laboratory for Compositional Systems and Methods](https://taltech.ee/en/contacts/laboratory-compositional-systems-and-methods) at the [Department of Software Science](https://taltech.ee/en/department-of-software-science) of [Tallin University of Technology](https://taltech.ee/en/). My stay with them in May 2023 set the stage for the birth and primary development of this work, fueled by their warm hospitality and vibrant scholarly atmosphere.

This work is built upon the collaborative efforts of two exceptional contributors:

- [tetrapharmakon](https://github.com/tetrapharmakon), my partner in crime for [moirai](https://github.com/tetrapharmakon/moirai), the projects' first iteration.
- [iwilare](https://github.com/iwilare), who saw potential in our initial idea and pushed it forward with their own fork [moirphism](https://github.com/iwilare/moirphism).

Without them, their shared enthusiasm, and our countless fruitful discussions, `string-diagrams` simply wouldn't be.
