FROM ubuntu:18.04

ARG CARDANO_TAG=1.26.2
ARG CABAL_VERSION=3.4.0.0
ARG GHC_VERSION=8.10.2

# Install build dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && \
    apt-get install automake build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ tmux git jq wget libncursesw5 libtool autoconf -y

# Install cabal

RUN wget https://downloads.haskell.org/cabal/cabal-install-${CABAL_VERSION}/cabal-install-${CABAL_VERSION}-x86_64-ubuntu-16.04.tar.xz \
    && tar -xf cabal-install-${CABAL_VERSION}-x86_64-ubuntu-16.04.tar.xz \
    && rm cabal-install-${CABAL_VERSION}-x86_64-ubuntu-16.04.tar.xz \
    && mv cabal /usr/bin/ \
    && cabal update

# Install GHC
RUN wget https://downloads.haskell.org/~ghc/${GHC_VERSION}/ghc-${GHC_VERSION}-x86_64-deb9-linux.tar.xz \
    && tar -xf ghc-${GHC_VERSION}-x86_64-deb9-linux.tar.xz \
    && rm ghc-${GHC_VERSION}-x86_64-deb9-linux.tar.xz \
    && cd ghc-${GHC_VERSION} \
    && ./configure \
    && make install && cd ..

# Install libsodium
RUN git clone https://github.com/input-output-hk/libsodium \
    && cd libsodium \
    && echo git checkout 66f017f1 \
    && ./autogen.sh && ./configure && make && make install
    
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

# Install cardano-node
RUN echo "Building $CARDANO_TAG..." \
    && echo $CARDANO_TAG > /CARDANO_TAG
RUN mkdir -p /cardano-node/
RUN git clone https://github.com/input-output-hk/cardano-node.git \
    && cd cardano-node \
    && git fetch --all --recurse-submodules --tags \
    && git checkout tags/$CARDANO_TAG
WORKDIR /cardano-node/

RUN cabal configure --with-compiler=ghc-8.10.2
RUN echo "package cardano-crypto-praos" >>  cabal.project.local && echo "  flags: -external-libsodium-vrf" >>  cabal.project.local
RUN cabal build all
RUN cabal install cardano-node cardano-cli
# Installed in /root/.cabal/bin/cardano-node and /root/.cabal/bin/cardano-cli
