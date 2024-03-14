{
  # nixpkgs deps
  dockerTools,
  git, pybind11, python, eigen, catch2, cmake, gnumake, gcc, binutils, bash, tree, which, coreutils,

  # local deps
  nix-nix
} :

dockerTools.buildLayeredImage {
  name = "docker-nix-image";
  tag = "v1";
  created = "now";  # warning: breaks deterministic output !

  # probably can use this:
  #fromImage = mumble nix docker image

  contents = [ nix-nix

               git

               pybind11
               python

               eigen
               catch2

               cmake
               gnumake
               gcc
               binutils
               bash
               tree
               which
               coreutils
             ];
}

