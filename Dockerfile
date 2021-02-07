FROM ubuntu:focal

# Args + Defaults
ARG CABAL_VERSION=3.2.0.0
ARG GHC_VERSION=8.10.2
ARG CARDANO_TAG_VERSION=1.25.1

# Skip interactive installs
ENV DEBIAN_FRONTEND=noninteractive

#Deps
RUN apt-get -y update && apt-get install -y \
    automake \ 
    build-essential \ 
    pkg-config \ 
    libffi-dev \ 
    libgmp-dev \ 
    libssl-dev \ 
    libtinfo-dev \
    libsystemd-dev \
    zlib1g-dev \
    make \
    g++ \
    tmux \
    git \
    jq \
    wget \
    libncursesw5 \
    libtool \
    autoconf \
    libsodium-dev

RUN mkdir -p ~/.local/bin
ENV PATH="/root/.local/bin:$PATH"
#Cabal
RUN wget https://downloads.haskell.org/~cabal/cabal-install-${CABAL_VERSION}/cabal-install-${CABAL_VERSION}-x86_64-unknown-linux.tar.xz && \
    tar -xf cabal-install-${CABAL_VERSION}-x86_64-unknown-linux.tar.xz && \
    rm cabal-install-${CABAL_VERSION}-x86_64-unknown-linux.tar.xz cabal.sig
RUN cp cabal ~/.local/bin/
RUN cabal update

# GHC
RUN wget https://downloads.haskell.org/ghc/${GHC_VERSION}/ghc-${GHC_VERSION}-x86_64-deb9-linux.tar.xz && \
    tar -xf ghc-${GHC_VERSION}-x86_64-deb9-linux.tar.xz && \
    rm ghc-${GHC_VERSION}-x86_64-deb9-linux.tar.xz
RUN cd ghc-${GHC_VERSION} && \ 
    ./configure && \ 
    make install

# Libsodium
WORKDIR /root
RUN git clone https://github.com/input-output-hk/Libsodium
WORKDIR /root/Libsodium
RUN git checkout 66f017f1
RUN ./autogen.sh && \
    ./configure && \ 
    make && \ 
    make install

RUN export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
RUN export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"


WORKDIR /root
RUN git clone https://github.com/input-output-hk/cardano-node.git
WORKDIR /root/cardano-node
RUN git fetch --all --recurse-submodules --tags
RUN git checkout tags/${CARDANO_TAG_VERSION}
RUN cabal configure --with-compiler=ghc-$(ghc --numeric-version)
RUN echo "package cardano-crypto-praos" >>  cabal.project.local && \
    echo "  flags: -external-libsodium-vrf" >>  cabal.project.local
RUN cabal build all
RUN cp -p ./dist-newstyle/build/x86_64-linux/ghc-${GHC_VERSION}/cardano-node-${CARDANO_TAG_VERSION}/x/cardano-node/build/cardano-node/cardano-node /usr/bin/
RUN cp -p ./dist-newstyle/build/x86_64-linux/ghc-${GHC_VERSION}/cardano-cli-${CARDANO_TAG_VERSION}/x/cardano-cli/build/cardano-cli/cardano-cli /usr/bin
RUN cabal install cardano-node cardano-cli \ 
    --enable-optimization=2 \
    --install-method=copy \
    --installdir=/root/.local/bin


