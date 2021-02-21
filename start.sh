#!/bin/bash
docker run \
    --name relay-node-1 \
    -p 3000:3000 \
    -p 12798:12798 \
    -e HOST_ADDR="0.0.0.0" \
    -e NODE_PORT="3000" \
    -e NODE_NAME="cardano-relay1" \
    -e NODE_RELAY="True" \
    -e CARDANO_NETWORK="main" \
    -e PROMETHEUS_HOST="0.0.0.0" \
    -e PROMETHEUS_PORT="12798" \
    -v $PWD/config/:/usr/local/cardano/config \
    -v $PWD/relay-node-1/db:/usr/local/cardano/db \
    cardano-node-docker