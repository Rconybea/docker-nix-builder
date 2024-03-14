1. docker container providing toolchain for projects that can build with nix
2. could instead use docker container provided by nixos:

```
docker run -ti ghcr.io/nixos/nix
```

The nixos-provided image contains:
`nix`, `bashInteractive`, `coreutils-full`, `gnutar`, `gzip`, `gnugrep`, `which`, `curl`, `less`, `wget`, `man`, `cacert.out`, `findutils`.

