#!/bin/bash
cd $(dirname $BASH_SOURCE)

docker build -t cardano-node-builder .
docker run --name cardano-node-builder --rm -v $PWD:/out cardano-node-build bash -c 'cp /root/.cabal/bin/cardano-{node,cli} /out'

./cardano-node version
./cardano-cli version