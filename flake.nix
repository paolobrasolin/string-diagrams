{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        readTLPackagesList = filepath:
          pkgs.lib.pipe filepath [
            builtins.readFile
            (pkgs.lib.splitString "\n")
            (pkgs.lib.remove "")
          ];

        texlive = pkgs.texlive.combine (
          pkgs.lib.genAttrs (
            pkgs.lib.concatMap
            readTLPackagesList
            [
              ./dependencies/dev.texlive-packages.txt
              ./dependencies/build.texlive-packages.txt
              ./dependencies/runtime.texlive-packages.txt
            ]
          )
          (name: pkgs.texlive.${name})
        );
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bc
            coreutils
            entr
            gnumake
            gnused
            gnutar
            texlive
          ];
        };
        defaultPackage = pkgs.stdenvNoCC.mkDerivation rec {
          name = "string-diagrams";
          src = self;
          buildInputs = [pkgs.coreutils texlive];
          phases = ["unpackPhase" "buildPhase" "installPhase"];
          buildPhase = ''
            env \
              TEXMFVAR=$(pwd)/.texmf-var \
              TEXMFHOME=$(pwd)/.texmf-home  \
              TEXMFCACHE=$(pwd)/.texmf-cache \
              TEXMFCONFIG=$(pwd)/.texmf-config \
              SOURCE_DATE_EPOCH=${toString self.lastModified} \
              FORCE_SOURCE_DATE=1 \
            latexmk \
              -gg -interaction=batchmode -pdf \
              -pretex="\pdftrailerid{}\relax" -usepretex  \
            ${name}.dtx
            echo ${toString self.lastModified}
          '';
          installPhase = ''
            mkdir -p $out
            cp ${name}.{dtx,ins,sty,pdf} $out/
          '';
        };
      }
    );
}
