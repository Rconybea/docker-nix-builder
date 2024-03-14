{
  # nixpkgs deps
  dockerTools,
  nix, git, pybind11, python, eigen, catch2, cmake, gnumake, gcc, shadow, binutils, bashInteractive, bash, tree, which, coreutils, lib,
} :

let
  users = {
    # root user.  
    root = {
      uid = 0;
      gid = 0;

      shell = "${bashInteractive}/bin/bash";
      #shell = "${bashInteractive}/bin/bash";
      # TODO: probably move to /root
      home = "/";
      groups = [ "root" ];
      description = "system administrator";
    };

    # no-privilege user
    nobody = {
      uid = 65534;
      gid = 65534;

      shell = "/bin/false";
      home = "/var/empty";
      groups = [ "nobody" ];
      description = "null-privilege account";
    };

    # nix builder
    nixbld1 = {
      uid = 30001;
      gid = 30000;

      shell = "/bin/false";
      home = "/var/empty";
      groups = [ "nixbld" ];
      description = "nix build user 1";
    };
      
    # nix builder
    nixbld2 = {
      uid = 30002;
      gid = 30000;

      shell = "/bin/false";
      home = "/var/empty";
      groups = [ "nixbld" ];
      description = "nix build user 2";
    };
  };

  groups = {
    root.gid = 0;
    nixbld.gid = 30000;
    nobody.gid = 65534;
  };    

  user2passwd = (key: { uid, gid, home, description, shell, groups}: "${key}:x:${toString uid}:${toString gid}:${description}:${home}:${shell}");

  user2shadow = (key: { uid, gid, home, description, shell, groups}: "${key}:!:1::::::");

  # contents of /etc/passwd
  passwd = (lib.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs user2passwd users)));

  # contents of /etc/shadow
  shadow = (lib.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs user2shadow users)));

  # figure out which users belong to which groups
  #
  # group2member_map :: {group, [user]}
  #
  group2member_map = (
    let
      # mappings :: [{user, group}]
      #
      # e.g. [ {user="nixbld1"; group="nixbld"; }, {user="nixbld2"; group="nixbld";}, ... ]
      #
      mappings = (
        builtins.foldl'
          (acc: user:
            let
              groups = users.${user}.groups or [ ];
            in
              acc ++ (map (group: { inherit user group; }) groups)
          )
          [ ]
          (lib.attrNames users)
      );
    in
      (
        builtins.foldl'
          (
            # v :: {user, group}
            acc: v: acc // { ${v.group} = acc.${v.group} or [ ] ++ [ v.user ]; }
          )
          { }
          mappings)
  );

  # group2group :: gname -> gid -> groupline
  #
  # e.g. "nixbld" -> 30000 -> "nixbld:x:30000:nixbld1,nixbld2"
  # 
  group2group =
    (key : { gid }:
      let
        # member_list :: [user]
        member_list = group2member_map.${key} or [ ];
        memberlist_str = lib.concatStringsSep "," member_list;
      in
        "${key}:x:${toString gid}:${memberlist_str}");

  # contents of /etc/group
  group = (lib.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs group2group groups)));
  
in

dockerTools.buildLayeredImage {
  name = "docker-nix-builder";
  tag = "v1";
  created = "now";  # warning: breaks deterministic output !

  # probably can use this:
  #fromImage = mumble nix docker image

  contents = [ nix

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

  enableFakechroot = true;

  fakeRootCommands = ''
    mkdir -p /etc
    mkdir -p /var
    mkdir -p /nix/var/nix/gcroots/auto

    mkdir -p /usr/bin
    ln -s ${coreutils}/bin/env /usr/bin/env

    mkdir -p /.config/nix
    echo "experimental-features = nix-command flakes" > .config/nix/nix.conf

    echo "${passwd}" > /etc/passwd
    echo "${shadow}" > /etc/shadow
    echo "${group}" > /etc/group

    mkdir -p /tmp
    mkdir -p /var/tmp

    chmod 1777 /tmp
    chmod 1777 /var/tmp
  '';
}

