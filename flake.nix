{
  description = "Create string diagrams with LaTeX";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # NOTE: the final release of each TeX Live we support, from the first day that nixpkgs had it with all its builds in the binary cache; pinned by commit, so that they never move. The oldest (LaTeX 2023-11-01, expl3 2024-02-20, pgf 3.1.10) is what the package asks for.
    nixpkgs-texlive-2023.url = "github:NixOS/nixpkgs/e52b38ae97ac6683b81bed7fc07f5d896186e4b3";
    nixpkgs-texlive-2024.url = "github:NixOS/nixpkgs/43d524e00e8299f0d0003cf956151bfc5b66b9ee";
    nixpkgs-texlive-2025.url = "github:NixOS/nixpkgs/9114a731a9c6b2b3bdf6865b7f6134bccc58afaf";
    systems.url = "github:nix-systems/default";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-texlive-2023,
    nixpkgs-texlive-2024,
    nixpkgs-texlive-2025,
    systems,
  }: let
    inherit (nixpkgs) lib;

    # NOTE: bump this in the release commit, along with the changelog.
    version = "0.5.0-dev";

    # NOTE: the commit date stamps the package and seeds SOURCE_DATE_EPOCH, so each commit always yields the same artifacts.
    date = lib.concatStringsSep "-" [
      (builtins.substring 0 4 self.lastModifiedDate)
      (builtins.substring 4 2 self.lastModifiedDate)
      (builtins.substring 6 2 self.lastModifiedDate)
    ];

    readTLPackagesList = filepath:
      lib.pipe filepath [
        builtins.readFile
        (lib.splitString "\n")
        (lib.remove "")
      ];

    runtimeTLPackages = readTLPackagesList ./dependencies/runtime.texlive-packages.txt;
    buildTLPackages = readTLPackagesList ./dependencies/build.texlive-packages.txt;
    devTLPackages = readTLPackagesList ./dependencies/dev.texlive-packages.txt;

    # NOTE: all artifacts are platform independent, so the systems only say where we can build them; consumers can override them via the systems input.
    perSystem = lib.genAttrs (import systems) (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        # NOTE: the tests on a TeX Live of the past, against the same .tlg files.
        texliveCheck = year: nixpkgsOfYear: let
          pkgsOfYear = nixpkgsOfYear.legacyPackages.${system};
          texliveOfYear = pkgsOfYear.texlive.combine {inherit (pkgsOfYear.texlive) scheme-small pgf l3build;};
        in
          pkgs.runCommand "string-diagrams-texlive-${year}" {
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions [
                ./build.lua
                ./string-diagrams.dtx
                ./string-diagrams.ins
                ./testfiles
              ];
            };
            nativeBuildInputs = [texliveOfYear pkgs.writableTmpDirAsHomeHook];
            # NOTE: l3build resets TEXMFCNF, which breaks the formats of these old nixpkgs (nixpkgs#352194).
            TEXMF = "${texliveOfYear}/";
          } ''
            cp -r $src/. .
            chmod -R u+w .
            l3build check
            mkdir $out
          '';
      in rec {
        texlive = pkgs.texliveInfraOnly.withPackages (
          ps: map (name: ps.${name}) (runtimeTLPackages ++ buildTLPackages ++ devTLPackages)
        );

        devShell = pkgs.mkShell {
          # NOTE: l3build uploads to CTAN with curl.
          packages = [texlive pkgs.curl];
        };

        formatter = pkgs.alejandra;

        # The CTAN upload (out) and the TDS tree (tds), from a single l3build run.
        ctan = pkgs.stdenvNoCC.mkDerivation {
          pname = "string-diagrams-ctan";
          inherit version;

          outputs = ["out" "tds"];

          src = lib.fileset.toSource {
            root = ./.;
            fileset = lib.fileset.unions [
              ./build.lua
              ./CHANGELOG.md
              ./README.md
              ./string-diagrams.dtx
              ./string-diagrams.ins
              ./testfiles
            ];
          };

          nativeBuildInputs = [
            texlive
            pkgs.zip
            pkgs.writableTmpDirAsHomeHook
          ];

          env = {
            SOURCE_DATE_EPOCH = toString self.lastModified;
            FORCE_SOURCE_DATE = "1";
          };

          dontConfigure = true;
          dontFixup = true;

          buildPhase = ''
            runHook preBuild
            l3build tag --date ${date} ${version}
            l3build ctan
            runHook postBuild
          '';

          # NOTE: l3build stamps zip entries with the current time, so we zip the CTAN tree again deterministically.
          installPhase = ''
            runHook preInstall

            pushd build/distrib/ctan
            find string-diagrams -exec touch --no-dereference --date=@$SOURCE_DATE_EPOCH {} +
            chmod -R u=rwX,go=rX string-diagrams
            find string-diagrams -type f | LC_ALL=C sort | TZ=UTC zip -X -D -@ string-diagrams.zip
            mv string-diagrams.zip $out
            popd

            # NOTE: l3build always zips the TDS tree too, but we only need the tree itself.
            rm build/distrib/tds/string-diagrams.tds.zip
            cp -r build/distrib/tds $tds

            runHook postInstall
          '';
        };

        # The package in the shape expected by texlive.withPackages.
        string-diagrams = pkgs.stdenvNoCC.mkDerivation {
          pname = "string-diagrams";
          inherit version;

          outputs = ["tex" "texdoc" "texsource"];

          # NOTE: multiple-outputs.sh fails if $out is not defined
          preHook = ''
            out="''${tex-}"
          '';

          dontUnpack = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall
            mkdir -p $tex $texdoc $texsource
            cp -r --no-preserve=mode ${ctan.tds}/tex $tex/
            cp -r --no-preserve=mode ${ctan.tds}/doc $texdoc/
            cp -r --no-preserve=mode ${ctan.tds}/source $texsource/
            runHook postInstall
          '';

          passthru.tlDeps = ps: map (name: ps.${name}) runtimeTLPackages;

          meta = {
            description = "Create string diagrams with LaTeX and TikZ";
            homepage = "https://github.com/paolobrasolin/string-diagrams";
            license = lib.licenses.lppl13c;
            platforms = lib.platforms.all;
          };
        };

        # The project site: the examples of the manual, rendered and editable, with the manual itself.
        site = pkgs.stdenvNoCC.mkDerivation {
          pname = "string-diagrams-site";
          inherit version;

          src = lib.fileset.toSource {
            root = ./.;
            fileset = lib.fileset.unions [
              ./build.lua
              ./string-diagrams.dtx
              ./string-diagrams.ins
              ./site
            ];
          };

          nativeBuildInputs = [
            texlive
            pkgs.poppler-utils
            pkgs.writableTmpDirAsHomeHook
          ];

          env = {
            SOURCE_DATE_EPOCH = toString self.lastModified;
            FORCE_SOURCE_DATE = "1";
          };

          dontConfigure = true;
          dontFixup = true;

          buildPhase = ''
            runHook preBuild
            l3build tag --date ${date} ${version}
            l3build doc
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            texlua site/generate.lua build $out ${version}
            runHook postInstall
          '';
        };

        serve-site = pkgs.writeShellApplication {
          name = "string-diagrams-serve-site";
          runtimeInputs = [pkgs.python3];
          text = ''
            echo "Serving the site at http://127.0.0.1:8000/"
            python3 -m http.server --bind 127.0.0.1 --directory ${site} 8000
          '';
        };

        checks = {
          # NOTE: building the site checks it too: the showcase compiles, the page lists exactly the examples of site/showcase, and the package has no \endinput, which the live demo can't handle.
          inherit site;

          # NOTE: TeX Live already ships string-diagrams, so this checks our build replaces it; texliveBasic lacks pgf, so this also checks tlDeps.
          with-packages =
            pkgs.runCommand "string-diagrams-with-packages" {
              nativeBuildInputs = [
                ((pkgs.texliveBasic.withPackages (ps: [ps.string-diagrams])).withPackages (_: [string-diagrams]))
                pkgs.writableTmpDirAsHomeHook
              ];
            } ''
              cat > test.tex <<'EOF'
              \documentclass{article}
              \usepackage{string-diagrams}
              \begin{document}
              \begin{tikzpicture}
                \node[box=0/1/0/1] (A) {A};
                \wires{ A = { west = @.west, east = @.east } }
              \end{tikzpicture}
              \end{document}
              EOF
              pdflatex -interaction=nonstopmode -halt-on-error test.tex
              grep -F "Package: string-diagrams ${lib.replaceStrings ["-"] ["/"] date} v${version}" test.log
              mkdir $out
            '';

          texlive-2023 = texliveCheck "2023" nixpkgs-texlive-2023;
          texlive-2024 = texliveCheck "2024" nixpkgs-texlive-2024;
          texlive-2025 = texliveCheck "2025" nixpkgs-texlive-2025;

          # NOTE: with tagging on, LaTeX collects each formula whole, which a box label opened and closed in two places would break.
          tagging =
            pkgs.runCommand "string-diagrams-tagging" {
              nativeBuildInputs = [
                (pkgs.texliveBasic.withPackages (ps: [string-diagrams ps.latex-lab ps.tagpdf ps.pdfmanagement-testphase ps.lm]))
                pkgs.writableTmpDirAsHomeHook
              ];
            } ''
              cat > test.tex <<'EOF'
              \DocumentMetadata{tagging=on, lang=en}
              \documentclass{article}
              \usepackage{lmodern}
              \usepackage{string-diagrams}
              \begin{document}
              \begin{tikzpicture}[alt={f, then g, as a string diagram}]
                \node[box=1/0/1/0] (f) at (0,0) {f};
                \node[box=1/0/1/0, box math=false] (g) at (.6,1.4) {$g$};
                \wires{ @ = f.south.1, f.north.1 = ["$A$"] g.south.1, g.north.1 = @ }
              \end{tikzpicture}
              \end{document}
              EOF
              pdflatex -interaction=nonstopmode -halt-on-error test.tex
              mkdir $out
            '';

          # NOTE: CTAN maintainers prefer a flat upload (no TDS zip) for simple packages.
          ctan-is-flat = pkgs.runCommand "string-diagrams-ctan-is-flat" {nativeBuildInputs = [pkgs.unzip];} ''
            unzip -Z1 ${ctan} | tee entries
            if grep -v -E '^string-diagrams/[^/]+$' entries; then exit 1; fi
            if grep -F '.tds.zip' entries; then exit 1; fi
            mkdir $out
          '';
        };

        watch = pkgs.writeShellApplication {
          name = "string-diagrams-watch";
          runtimeInputs = [texlive pkgs.entr];
          text = ''
            printf '%s\n' string-diagrams.dtx string-diagrams.ins build.lua | entr -c l3build doc
          '';
        };

        update-deps = pkgs.writeShellApplication {
          name = "string-diagrams-update-deps";
          runtimeInputs = [texlive pkgs.bc pkgs.coreutils pkgs.gnugrep pkgs.gnused];
          text = ''
            tex -interaction=batchmode string-diagrams.ins
            bash ${./dev/make_sty_dep.sh}
            bash ${./dev/dep_to_pkg.sh} --source string-diagrams.sty.dep --target dependencies/runtime.texlive-packages.txt --remove "snapshot"
            bash ${./dev/make_pdf_dep.sh}
            bash ${./dev/dep_to_pkg.sh} --source string-diagrams.pdf.dep --target dependencies/build.texlive-packages.txt --remove "snapshot base" --append "collection-fontsrecommended"
          '';
        };
      }
    );
  in {
    packages =
      lib.mapAttrs (_: s: {
        inherit (s) ctan string-diagrams site;
        default = s.string-diagrams;
      })
      perSystem;

    checks = lib.mapAttrs (_: s: s.checks) perSystem;

    apps =
      lib.mapAttrs (_: s: {
        watch = {
          type = "app";
          program = lib.getExe s.watch;
          meta.description = "Rebuild the documentation whenever the sources change";
        };
        update-deps = {
          type = "app";
          program = lib.getExe s.update-deps;
          meta.description = "Regenerate the lists of TeX Live dependencies";
        };
        serve-site = {
          type = "app";
          program = lib.getExe s.serve-site;
          meta.description = "Build the site and serve it locally";
        };
      })
      perSystem;

    devShells =
      lib.mapAttrs (_: s: {
        default = s.devShell;
      })
      perSystem;

    formatter = lib.mapAttrs (_: s: s.formatter) perSystem;
  };
}
