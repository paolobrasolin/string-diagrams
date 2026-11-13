# Contributing

This guide is for work on the package itself. For ideas and bug reports, use the [issue tracker](https://github.com/paolobrasolin/string-diagrams/issues).

## Development environment

The Nix flake supplies all the tools. `nix develop` gives you a TeX Live with l3build and all the dependencies. [direnv](https://direnv.net/) does the same through `.envrc`.

| Command | What it does |
| --- | --- |
| `nix run .#watch` | Build the documentation (`string-diagrams.pdf`) again each time the sources change |
| `l3build check` | Run the regression tests in `testfiles/` |
| `l3build save <test>` | Record the expected output of a test |
| `nix flake check` | Build everything and run all the checks |
| `nix build .#ctan` | Build the zip to upload to CTAN |
| `nix build` | Build the TeX Live package, for use with `texlive.withPackages` |
| `nix fmt` | Format the Nix files |
| `nix run .#serve-site` | Build the project site and serve it at http://127.0.0.1:8000/ |

Run `l3build` commands inside the development shell.

## Tests

The regression tests in `testfiles/` record what the package does.

- `l3build check` runs them with pdfTeX, XeTeX and LuaTeX. It compares their logs with the `.tlg` files.
- Each test starts from `testfiles/support/stridi-test.tex`. This file sets up the test, and has helpers that log points, anchors and drawings.

`nix flake check` also runs the tests on the final TeX Live of 2023, 2024 and 2025, against the same `.tlg` files.

- Each TeX Live comes from a nixpkgs input of the flake. The input is pinned by commit to the first day that nixpkgs had that TeX Live with all its builds in the binary cache.
- The oldest TeX Live gives the versions that the package asks for.
- The `nixpkgs` input follows `nixos-unstable`, so it brings each new TeX Live automatically. When it does, pin the year that it leaves behind in the same way.

Two prefixes in the title of a test mark behavior that is not final:

- `BUG:` marks behavior that is known to be wrong. A comment above the test says what must occur instead.
- `TBC:` marks behavior that is not yet confirmed as intended. A comment above the test has the open question.

When you fix the bug or make the decision, remove the prefix and update the `.tlg` files.

## Documentation

The manual is the documentation part of `string-diagrams.dtx`. `l3build doc` builds it.

Write the manual with the writing rules of [ASD-STE100](https://www.asd-ste100.org/) (Simplified Technical English), without its dictionary:

- Write short sentences, with one idea in each.
- Use the active voice.
- Use the imperative for instructions.
- Use the same word for the same thing.
- Use lists or numbered steps where they help.
- Keep the vocabulary of TikZ.

This guide follows the same rules.

Every example in the manual has a name, as in `\begin{tcblisting}{example=box}`. `l3build doc` fails if an example does not compile.

Record each change in the commit that makes it:

- In `CHANGELOG.md`, under `[Unreleased]`, if users can see the change.
- In `string-diagrams.dtx`, with a date in the `function` environment of the command or key. A new command or key gets an `added=` date. A change to what a command or key does gets an `updated=` date.

The manual has no change history. `CHANGELOG.md` is the only one.

An `added=` or `updated=` date cannot be later than the date of the build. `nix flake check` and CI take the date of the build from the last commit, in UTC. Thus, between your midnight and midnight in UTC, the date of today can be in the future there.

## Dependencies

`dependencies/` lists the TeX Live packages that the project needs, in three lists:

- `runtime` has the packages that the package loads.
- `build` has the packages that its documentation loads.
- `dev` has the tools.

The `runtime` and `build` lists are generated. When you change what the package or its documentation loads:

1. Add each new package to the correct list by hand. The generation runs in the environment that these lists make, so it needs the new package there first.
2. Run `nix run .#update-deps`.

Keep the `dev` list by hand.

## Site

The project site is https://paolobrasolin.github.io/string-diagrams/. Its source is in `site/`:

- `index.html` and `llms.txt` are templates.
- `showcase/` has the examples of the live demo.
- `generate.lua` builds the site from a build of the documentation.

The page lists the showcase in a comment, with one example on each line: its name, tab label, caption and alt text. `llms.txt` also gets the examples of the manual, in their order. Each one has a name in the manual, as in `\begin{tcblisting}{example=box}`.

The page and `llms.txt` are written by hand, apart from the examples. When the package changes what users write or see, update them too:

- `llms.txt` describes every key and command, and quotes every error message of the package.
- The page says which version its examples need.

Their text follows ASD-STE100 in full, with its dictionary. To check the site, serve it with `nix run .#serve-site` and try the live demo.

`nix flake check` builds the site. It fails in three cases:

- A showcase example does not compile.
- The page and `site/showcase` do not list the same examples.
- The package has an `\endinput`. The live demo cannot handle it: the demo pastes the package into the preamble of TikZJax, which runs TeX in the browser.

CI deploys the site to GitHub Pages when you push a release tag. To deploy it at another time, run the CI workflow by hand from the Actions tab of the repository:

- From a tag, it deploys that release again.
- From a branch, it deploys the development version.

Set up Pages one time, in the settings of the repository: make GitHub Actions the source, and let release tags (`v*`) deploy to the `github-pages` environment.

## Reproducibility

Builds are reproducible. The version comes from `flake.nix`. The date comes from the last commit, which also sets `SOURCE_DATE_EPOCH`.

- To check this on your machine, run `nix build .#ctan --rebuild`.
- For release tags and pull requests, CI checks that Linux on Intel, Linux on ARM and macOS make the same zip.

## Releasing

1. Check that the changelog, the manual, `site/llms.txt` and the page of the site all describe the release. Check that `nix flake check` passes.
2. Prepare a release commit:
   - Set `version` in `flake.nix` to the new version, for example `0.3.0`.
   - Move the `[Unreleased]` entries of `CHANGELOG.md` to a section for the new version, and update the links at the bottom.
   - If the release is a major upgrade that CTAN should announce, start that section with a short summary of the improvements, before its first `###` heading. CTAN does not announce bug fixes or minor additions. Without a summary, CTAN announces nothing.
3. Tag the commit with the version and the prefix `v`, for example `v0.3.0`, and push the tag. CI then does these steps in order:
   1. It builds and checks the tag on Linux on Intel, Linux on ARM and macOS.
   2. It checks that the tag matches `flake.nix`, and that the changelog has notes for it.
   3. It validates the upload with CTAN, and treats warnings as failures.
   4. It publishes a GitHub release with the notes of the changelog.
   5. It uploads the zip to CTAN, with the summary, if there is one, as the announcement.
   6. It deploys the site.

   CI does steps 4 to 6 only if steps 1 to 3 pass. If a step fails, fix the cause and run the job again. If the upload to CTAN failed, first look for the confirmation email of CTAN: the upload can be complete in spite of the failure.
4. Set `version` in `flake.nix` to the next minor version with `-dev`, such as `0.5.0-dev`. This version only labels development builds: the next release commit sets the real version. When you know that the next release will be a major one, change it to that, such as `1.0.0-dev`.

To validate an upload with CTAN from your machine:

1. Put the zip in place with `nix build .#ctan && cp result string-diagrams-ctan.zip`.
2. Run `l3build upload <version>`.
3. Answer `n` to the question about submitting it.
