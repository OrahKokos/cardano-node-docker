FROM ubuntu:focal

# Args + Defaults
ARG CABAL_VERSION=3.2.0.0
ARG GHC_VERSION=8.10.2
ARG CARDANO_TAG_VERSION=1.25.1

# Skip interactive installs
ENV DEBIAN_FRONTEND=noninteractive

# Const
ENV DOWNLOAD_FOLDER=/var/tmp
ENV BIN_FOLDER=/usr/local/bin
ENV LIB_FOLDER=/usr/local/lib

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
    git \
    jq \
    curl \
    wget \
    libncursesw5 \
    libtool \
    autoconf \
    libsodium-dev

#Cabal
RUN wget https://downloads.haskell.org/~cabal/cabal-install-${CABAL_VERSION}/cabal-install-${CABAL_VERSION}-x86_64-unknown-linux.tar.xz -O ${DOWNLOAD_FOLDER}/cabal.tar.xz && \
    tar -xf ${DOWNLOAD_FOLDER}/cabal.tar.xz -C ${BIN_FOLDER} && \
    rm ${DOWNLOAD_FOLDER}/cabal.tar.xz ${BIN_FOLDER}/cabal.sig
RUN cabal update

#GHC
RUN wget https://downloads.haskell.org/ghc/${GHC_VERSION}/ghc-${GHC_VERSION}-x86_64-deb9-linux.tar.xz -O ${DOWNLOAD_FOLDER}/ghc.tar.xz
RUN tar -xf ${DOWNLOAD_FOLDER}/ghc.tar.xz -C ${DOWNLOAD_FOLDER}
RUN cd ${DOWNLOAD_FOLDER}/ghc-${GHC_VERSION} && ./configure && make install

# Libsodium
RUN git clone https://github.com/input-output-hk/Libsodium ${DOWNLOAD_FOLDER}/Libsodium
RUN cd ${DOWNLOAD_FOLDER}/Libsodium && \
    git checkout 66f017f1 && \
    ./autogen.sh && \
    ./configure && \ 
    make && \ 
    make install

RUN export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
RUN export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

# Cardano
RUN git clone https://github.com/input-output-hk/cardano-node.git ${DOWNLOAD_FOLDER}/cardano-node
RUN cd ${DOWNLOAD_FOLDER}/cardano-node && \
    git fetch --all --recurse-submodules --tags && \
    git checkout tags/${CARDANO_TAG_VERSION} && \
    cabal configure --with-compiler=ghc-$(ghc --numeric-version) && \
    echo "package cardano-crypto-praos" >>  cabal.project.local && \
    echo "  flags: -external-libsodium-vrf" >>  cabal.project.local
RUN cd ${DOWNLOAD_FOLDER}/cardano-node && \
    cabal clean && \
    cabal update && \
    cabal build all
RUN cp -p ${DOWNLOAD_FOLDER}/cardano-node/dist-newstyle/build/x86_64-linux/ghc-${GHC_VERSION}/cardano-node-${CARDANO_TAG_VERSION}/x/cardano-node/build/cardano-node/cardano-node ${BIN_FOLDER} && \
    cp -p ${DOWNLOAD_FOLDER}/cardano-node/dist-newstyle/build/x86_64-linux/ghc-${GHC_VERSION}/cardano-cli-${CARDANO_TAG_VERSION}/x/cardano-cli/build/cardano-cli/cardano-cli ${BIN_FOLDER}



