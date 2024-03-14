{
  description = "docker nix builder (prepared using nix too)";

  # to determine specific hash for nixpkgs:
  # 1. $ cd ~/proj/nixpkgs
  # 2. $ git checkout release-23.05
  # 3. $ git fetch
  # 4. $ git pull
  # 5. $ git log -1
  #    take this hash,  then substitue for ${hash} in:
  #      inputs.nixpkgs.url = "https://github.com/NixOS/nixpkgs/archive/${hash}.tar.gz";
  #    below

  inputs.nixpkgs.url = "https://github.com/NixOS/nixpkgs/archive/217b3e910660fbf603b0995a6d2c3992aef4cc37.tar.gz"; # asof 10mar2024

  inputs.flake-utils.url = "github:numtide/flake-utils";

  #inputs.libgit2-path = { url = "github:libgit2/libgit2"; flake = false; };

  # NOTE: version taken from ~/proj/nix/.version
  #inputs.nix-nix-path = { url = "github:Nixos/nix"; flake = false; };

  outputs
  = { self,
      nixpkgs,
      flake-utils,
      #libgit2-path,
      #nix-nix-path,
    } :
      let
        #inherit (nixpkgs) lib;
        #inherit (lib) fileset;

        out
        = system :
          let
            pkgs = nixpkgs.legacyPackages.${system};

            appliedOverlay = self.overlays.default pkgs pkgs;

          in
            {
              #packages.nix-nix = appliedOverlay.nix-nix;
              packages.docker-nix-builder = appliedOverlay.docker-nix-builder;

              packages.default = appliedOverlay.default;

            };

      in
        flake-utils.lib.eachDefaultSystem
          out
        //
        {
          overlays.default = final: prev:
            (
              let
                stdenv = prev.stdenv;

                python3 = prev.python311Full;
                python3Packages = prev.python311Packages;
                pybind11 = python3Packages.pybind11;

                docker-nix-builder =
                  (prev.callPackage ./pkgs/docker-nix-builder.nix { #dockerTools = prev.dockerTools;
                                                                  python = python3;
                                                                  pybind11 = pybind11; });

              in
                {
                  default = docker-nix-builder;

                  docker-nix-builder = docker-nix-builder;
                });
        };
}
