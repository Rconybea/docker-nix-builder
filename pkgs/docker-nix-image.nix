{
  # nixpkgs deps
  dockerTools,

  # local deps
  nix-nix
} :

dockerTools.buildLayeredImage {
  name = "docker-nix-image";
  tag = "v1";
  created = "now";  # warning: breaks deterministic output !

  # probably can use this:
  #fromImage = mumble nix docker image

  contents = [ nix-nix ];
}

