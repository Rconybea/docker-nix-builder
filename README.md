1. docker container providing toolchain for projects that can build with nix
2. could instead use docker container provided by nixos:

```
docker run -ti ghcr.io/nixos/nix
```
That container provides `nix`, `bashInteractive`, `coreutils-full`, `gnutar`, `gzip`, `gnugrep`, `which`, `curl`, `less`, `wget`, `man`, `cacert.out`, `findutils`.

# build/update 

0. if changed any foo.nix files,  then 
```
$ cd ~/proj/docker-nix-builder
$ nix flake check
```

1. compile if necessary
```
$ cd ~/proj/docker-nix-builder  # directory containing this file
$ nix build -L --print-build-logs .#docker-nix-builder
```

2. upload to docker
```
$ docker load <./result  # i.e. docker load < ~/proj/docker-nix-builder/result
```

2a.
Note: to publish container to github, need a personal access token:

- on github.com/${myusername}:
  - visit profile (upper rhs or github.com)
    - developer settings (bottom of sidebar)
      - personal access tokens
        - tokens (classic)
          'generate a personal access token'

          scopes needed:
          - read:packages
          - write:packages
          - delete:packages

2b.
```
$ export CR_PAT=${token}
$ echo $CR_PAT | docker login ghcr.io -u rconybea --password-stdin
Login Succeeded
```

Docker keeps secret in `~/.docker/config.json`,  so don't need to remember token separately
unless want to use for something besides docker.

3.
tag image the way github expects,  i.e. format ghcr.io/${username}/${imagename}:${tag}
(tag should match `tag` argument to `dockerTools.buildLayeredImage` in `pkgs/docker-nix-image.nix`)

```
$ docker image tag docker-nix-builder:v1 ghcr.io/rconybea/docker-nix-builder:v1
```

4.
push to github container registry:
```
$ docker image push ghcr.io/rconybea/docker-nix-builder:v1
The push refers to repository [ghcr.io/rconybea/docker-nix-builder]
...omitted...
v1: digest: sha256:e1aad3df64c1ea2ed6674b354e22e3807a831bb8229fa3be399c21f87ea72cb6 size: 6192
```

5.
verify it's arrived by inspecting the gihub 'packages' tab [https://github.com/Rconybea?tab=packages]

image (github package) is initially private;  make it public from the package's 'setting' link

for example workflow using this image, see [https://github.com/rconybea/docker-action-example3]

# miscellaneous

## operate container locally

To test container locally:
```
$ docker run -i docker-nix-builder:v1 bash
```

## list available images

list available docker images

```
$ docker image ls
REPOSITORY                            TAG       IMAGE ID       CREATED         SIZE
docker-nix-builder                    v1        ce3fdf8fa87f   5 minutes ago   750MB
...
```

## delete old containers+images

```
$ docker container prune
$ docker image prune
```



