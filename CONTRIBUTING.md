# Contributing

This guide is about working on the package itself. For ideas and bug reports, the [issue tracker](https://github.com/paolobrasolin/string-diagrams/issues) is the place to go.

## Development environment

Everything comes from the Nix flake: `nix develop` (or [direnv](https://direnv.net/), through `.envrc`) gives you a TeX Live with l3build and all the dependencies.

| Command | What it does |
| --- | --- |
| `nix run .#watch` | Rebuild the documentation (`string-diagrams.pdf`) whenever the sources change |
| `l3build check` | Run the regression tests in `testfiles/` |
| `l3build save <test>` | Record the expected output of a test |
| `nix flake check` | Build everything and run all the checks |
| `nix build .#ctan` | Build the zip to upload to CTAN |
| `nix build` | Build the TeX Live package, for use with `texlive.withPackages` |
| `nix fmt` | Format the Nix files |

Run `l3build` commands inside the development shell.

## Dependencies

The TeX Live packages we need are listed in `dependencies/`: `runtime` is what the package loads, `build` is what its documentation loads, and `dev` is the tooling.

The `runtime` and `build` lists are generated: after changing what the package or its documentation loads, run `nix run .#update-deps`. Since the generation runs in the environment built from these very lists, add any new package to the right list by hand first. The `dev` list is maintained by hand.

## Reproducibility

Builds are reproducible: the version comes from `flake.nix`, and the date comes from the last commit, which also sets `SOURCE_DATE_EPOCH`. Running `nix build .#ctan --rebuild` checks this locally, and CI checks that Linux and macOS produce the same zip.

## Releasing

1. Prepare a release commit:
   - set `version` in `flake.nix` to the new version (e.g. `0.3.0`);
   - move the `[Unreleased]` entries of `CHANGELOG.md` to a section for the new version, and update the links at the bottom;
   - add the matching `\changes` entries to `string-diagrams.dtx`.
2. Tag the commit with the version prefixed by `v` (e.g. `v0.3.0`) and push the tag. CI checks that the tag matches `flake.nix`, publishes a GitHub release with the notes from the changelog, and uploads the zip to CTAN.
3. Set `version` in `flake.nix` to the next development version (e.g. `0.3.1-dev`).
