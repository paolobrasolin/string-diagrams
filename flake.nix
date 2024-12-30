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
      }
    );
}
