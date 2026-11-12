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
| `nix run .#serve-site` | Build the project site and serve it at http://127.0.0.1:8000/ |

Run `l3build` commands inside the development shell.

## Tests

The regression tests in `testfiles/` record what the package does: `l3build check` runs them with pdfTeX, XeTeX and LuaTeX, and compares their logs with the `.tlg` files. They all start from `testfiles/support/stridi-test.tex`, which sets them up and provides helpers to log points, anchors and drawings.

A test whose title starts with `BUG:` records behavior known to be wrong, and a comment above it says what should happen instead. `TBC:` marks behavior that is yet to be confirmed as intended, with the open question in a comment. The fix or decision drops the prefix and updates the `.tlg` files.

## Documentation

The manual is the documentation part of `string-diagrams.dtx`, and `l3build doc` builds it. Write it in plain English: short sentences of one idea each, the active voice, the imperative for instructions, the same word for the same thing, and lists or numbered steps where they help. Keep the vocabulary of TikZ.

Every example in the manual has a name, as in `\begin{tcblisting}{example=box}`, and `l3build doc` fails if an example doesn't compile.

The `added=` and `updated=` dates of l3doc can't be later than the date of the build, which `nix flake check` and CI take from the last commit, in UTC. Between your midnight and midnight in UTC, today's date can still be in the future there.

## Dependencies

The TeX Live packages we need are listed in `dependencies/`: `runtime` is what the package loads, `build` is what its documentation loads, and `dev` is the tooling.

The `runtime` and `build` lists are generated: after changing what the package or its documentation loads, run `nix run .#update-deps`. Since the generation runs in the environment built from these very lists, add any new package to the right list by hand first. The `dev` list is maintained by hand.

## Site

The project site, https://paolobrasolin.github.io/string-diagrams/, lives in `site/`. `index.html` and `llms.txt` are templates, `showcase/` holds the examples of the live demo, and `generate.lua` builds the site from a doc build. The page lists the showcase in a comment, one example per line, with its tab label, caption and alt text. `llms.txt` also gets the examples of the manual, in their order: each one is named in the manual, as in `\begin{tcblisting}{example=box}`.

The page and `llms.txt` are written by hand, apart from the examples, so when the package changes what users write or see, update them too: `llms.txt` describes every key and command and quotes every error message of the package, and the page says which version its examples need. Their text follows [ASD-STE100](https://www.asd-ste100.org/) (Simplified Technical English). To check the site, serve it with `nix run .#serve-site` and try the live demo.

`nix flake check` builds the site, and fails if a showcase example doesn't compile, if the page and `site/showcase` don't list the same examples, or if the package gains an `\endinput`, which the live demo can't handle: the demo pastes the package into the preamble of TikZJax, which runs TeX in the browser.

CI deploys the site to GitHub Pages when a release tag is pushed. To deploy it at another time, run the CI workflow by hand from the Actions tab of the repository: from a tag it redeploys that release, and from a branch it deploys the development version. Pages must be set up once in the settings of the repository: GitHub Actions as the source, and release tags (`v*`) allowed to deploy to the `github-pages` environment.

## Reproducibility

Builds are reproducible: the version comes from `flake.nix`, and the date comes from the last commit, which also sets `SOURCE_DATE_EPOCH`. Running `nix build .#ctan --rebuild` checks this locally, and CI checks that Linux on Intel, Linux on ARM and macOS produce the same zip.

## Releasing

1. Check that the changelog, the manual, `site/llms.txt` and the page of the site all describe the release, and that `nix flake check` passes.
2. Prepare a release commit:
   - set `version` in `flake.nix` to the new version (e.g. `0.3.0`);
   - move the `[Unreleased]` entries of `CHANGELOG.md` to a section for the new version, and update the links at the bottom;
   - if the release is a major upgrade worth announcing, start that section with a short summary of the improvements, before its first `###` heading (CTAN doesn't announce bug fixes or minor additions, and without a summary nothing is announced);
   - add the matching `\changes` entries to `string-diagrams.dtx`.
3. Tag the commit with the version prefixed by `v` (e.g. `v0.3.0`) and push the tag. CI builds and checks it on Linux on Intel, Linux on ARM and macOS, checks that the tag matches `flake.nix` and that the changelog has notes for it, and validates the upload with CTAN, treating warnings as failures. Only then does it publish a GitHub release with the changelog notes and upload the zip to CTAN, using the summary, if any, as the announcement, and deploy the site. If anything fails, fix it and rerun the job; if the CTAN upload step itself failed, first check for CTAN's confirmation email, since the upload may have gone through anyway.
4. Set `version` in `flake.nix` to the next minor version with `-dev`, such as `0.5.0-dev`. It only labels development builds, and the next release commit sets the actual version. Once you know the next release will be a major one, change it to that, such as `1.0.0-dev`.

To validate an upload with CTAN from your machine, put the zip in place with `nix build .#ctan && cp result string-diagrams-ctan.zip`, run `l3build upload <version>`, and answer `n` when asked whether to submit it.
