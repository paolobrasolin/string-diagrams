# string-diagrams

[![CTAN release][ctan-shield]][ctan-link]
[![GitHub release][release-shield]][release-link]
[![Project licence][licence-shield]][licence-link]

[ctan-shield]: https://img.shields.io/ctan/v/string-diagrams?label=CTAN
[ctan-link]: https://ctan.org/pkg/string-diagrams
[release-shield]: https://img.shields.io/github/v/release/paolobrasolin/string-diagrams?display_name=release
[release-link]: https://github.com/paolobrasolin/string-diagrams/releases/
[licence-shield]: https://img.shields.io/github/license/paolobrasolin/string-diagrams
[licence-link]: https://www.latex-project.org/lppl.txt

Create string diagrams with LaTeX!

Try it on the [project site](https://paolobrasolin.github.io/string-diagrams/): its examples compile in your browser.

`string-diagrams` is a LaTeX package designed for effortless and aesthetically pleasing creation of string diagrams.

## Getting Started

### Prerequisites

The only thing you need is an up-to-date LaTeX distribution including TikZ.

### Installation

The fastest way to hit the ground running is to download `string-diagrams` from CTAN via your package manager. For instance, TeXLive users can run `tlmgr install string-diagrams` or select `string-diagrams` from the GUI.

Alternatively, you can download the package from the [CTAN page](https://www.ctan.org/pkg/string-diagrams), unzip the archive, run `tex string-diagrams.ins` to generate `string-diagrams.sty`, and place it in your working directory.

For those who always live on the edge, the development version lives in this repository: generate `string-diagrams.sty` from a checkout with `tex string-diagrams.ins`, or, with Nix, take it straight from the flake, which replaces the copy shipped with TeX Live:

```nix
# inputs.string-diagrams.url = "github:paolobrasolin/string-diagrams";
pkgs.texliveSmall.withPackages (ps: [
  inputs.string-diagrams.packages.${pkgs.stdenv.hostPlatform.system}.default
])
```

### Usage

Detailed instructions are available in the [documentation](http://mirrors.ctan.org/graphics/pgf/contrib/string-diagrams/string-diagrams.pdf).

## Contributing

Got a fantastic idea? Noticed a bug? Contributions are more than welcome! Please feel free to share your thoughts via the [issue tracker](https://github.com/paolobrasolin/string-diagrams/issues).

For the adventurous, you can [fork the repository](https://github.com/paolobrasolin/string-diagrams/fork), create some magic, and [submit a pull request](https://github.com/paolobrasolin/string-diagrams/pulls). The [contributing guide](https://github.com/paolobrasolin/string-diagrams/blob/main/CONTRIBUTING.md) explains how to build and test the package.

## License

This project is licensed under the LPPL-1.3c License.

## Acknowledgements

Special gratitude goes to the [Laboratory for Compositional Systems and Methods](https://compose.ioc.ee/) of [Tallin University of Technology](https://taltech.ee/). My stay with them in May 2023 set the stage for the birth and primary development of this work, fueled by their warm hospitality and vibrant scholarly atmosphere.

This work is built upon the collaborative efforts of two exceptional contributors:

- [tetrapharmakon](https://github.com/tetrapharmakon), my partner in crime for [moirai](https://github.com/tetrapharmakon/moirai), the projects' first iteration.
- [iwilare](https://github.com/iwilare), who saw potential in our initial idea and pushed it forward with their own fork [moirphism](https://github.com/iwilare/moirphism).

Without them, their shared enthusiasm, and our fruitful discussions, `string-diagrams` simply wouldn't be.
