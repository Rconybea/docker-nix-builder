#!/usr/bin/env bash

set -x

docker load < ./result
docker image tag docker-nix-builder:v1 ghcr.io/rconybea/docker-nix-builder:v1
docker image push ghcr.io/rconybea/docker-nix-builder:v1
docker image ls
echo "visit https://github.com/rconybea?tab=packages to inspect"
