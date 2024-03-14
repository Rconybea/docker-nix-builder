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

  inputs.libgit2-path = { url = "github:libgit2/libgit2"; flake = false; };

  # NOTE: version taken from ~/proj/nix/.version
  inputs.nix-nix-path = { url = "github:Nixos/nix"; flake = false; };

  outputs
  = { self,
      nixpkgs,
      flake-utils,
      libgit2-path,
      nix-nix-path,
    } :
      let
        inherit (nixpkgs) lib;
        inherit (lib) fileset;

        out
        = system :
          let
            pkgs = nixpkgs.legacyPackages.${system};

            appliedOverlay = self.overlays.default pkgs pkgs;

          in
            {
              packages.nix-nix = appliedOverlay.nix-nix;
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

                # nix dependency #1
                default-busybox-sandbox-shell = final.busybox.override {
                  useMusl = true;
                  enableStatic = true;
                  enableMinimal = true;
                  extraConfig = ''
                CONFIG_FEATURE_FANCY_ECHO y
                CONFIG_FEATURE_SH_MATH y
                CONFIG_FEATURE_SH_MATH_64 y

                CONFIG_ASH y
                CONFIG_ASH_OPTIMIZE_FOR_SIZE y

                CONFIG_ASH_ALIAS y
                CONFIG_ASH_BASH_COMPAT y
                CONFIG_ASH_CMDCMD y
                CONFIG_ASH_ECHO y
                CONFIG_ASH_GETOPTS y
                CONFIG_ASH_INTERNAL_GLOB y
                CONFIG_ASH_JOB_CONTROL y
                CONFIG_ASH_PRINTF y
                CONFIG_ASH_TEST y
                '';
                };

                # nix dependency #2
                # TODO: move this into ./pkgs/libgit2-nix.nix
                libgit2-nix = prev.libgit2.overrideAttrs (attrs: {
                  src = libgit2-path;
                  version = libgit2-path.lastModifiedDate;
                  cmakeFlags = attrs.cmakeFlags or [] ++ [ "-DUSE_SSH=exec" ];
                });
                
                # nix dependency #3
                # TODO: move this into ./pkgs/boehmgc-nix-.nix
                boehmgc-nix =
                  (final.boehmgc.override { enableLargeConfig = true; }).overrideAttrs
                    (old: { patches = (old.patches or [])
                                      ++ [
                                        ./nix-patches/boehmgc-coroutine-sp-fallback.diff
                                        ./nix-patches/boehmgc-traceable_allocator-public.diff
                                      ];
                          });

                # adapted from nix repo toplevel flake.nix.
                # (focusing on call callPacakge on package.nix)
                nix-nix = 
                  (let
                    officialRelease = false;
                    versionSuffix = "xospecial";
                    
                  in (prev.callPackage ./pkgs/nix.nix  # was ./package.nix in ~/proj/nix
                    {
                      officialRelease = officialRelease;
                      fileset = fileset;  # note fileset is short-circuited by replacement src=nix-nix-path below #
                      stdenv = stdenv;
                      versionSuffix = versionSuffix;

                      boehmgc = boehmgc-nix;
                      libgit2 = libgit2-nix;
                      busybox-sandbox-shell = final.busybox-sandbox-shell or final.default-busybox-sandbox-shell;
                    } // {
                      #perl-bindings = final.nix-perl-bindings;
                    }).overrideAttrs
                    (old: { src = nix-nix-path; version = "2.22.0"; }));

              in
                {
                  nix-nix = nix-nix;
                });
        };
}
