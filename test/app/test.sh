#! /bin/bash

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

#- kvstore over socket, curl

export CMTHOME=${CMTHOME:-$HOME/.cometbft}
COMETBFT_CMD=${COMETBFT_CMD:-cometbft}
ABCI_CLI_CMD=${ABCI_CLI_CMD:-abci-cli}
KVSTORE_TEST_CMD=${KVSTORE_TEST_CMD:-bash test/app/kvstore_test.sh}

function cleanup {
    echo "Cleaning up..."
    kill -9 $pid_kvstore $pid_cometbft 2>/dev/null || true
}
trap cleanup EXIT

function check_dependencies {
    command -v $COMETBFT_CMD >/dev/null 2>&1 || { echo >&2 "cometbft command not found."; exit 1; }
    command -v $ABCI_CLI_CMD >/dev/null 2>&1 || { echo >&2 "abci-cli command not found."; exit 1; }
}

function kvstore_over_socket(){
    rm -rf "$CMTHOME"
    $COMETBFT_CMD init
    echo "Starting kvstore_over_socket"
    $ABCI_CLI_CMD kvstore > /dev/null &
    pid_kvstore=$!
    $COMETBFT_CMD node > cometbft.log &
    pid_cometbft=$!
    sleep 5

    echo "Running test"
    $KVSTORE_TEST_CMD "KVStore over Socket"
}

# start cometbft first
function kvstore_over_socket_reorder(){
    rm -rf "$CMTHOME"
    $COMETBFT_CMD init
    echo "Starting kvstore_over_socket_reorder (i.e., start cometbft first)"
    $COMETBFT_CMD node > cometbft.log &
    pid_cometbft=$!
    sleep 2
    $ABCI_CLI_CMD kvstore > /dev/null &
    pid_kvstore=$!
    sleep 5

    echo "Running test"
    $KVSTORE_TEST_CMD "KVStore over Socket"
}

check_dependencies
kvstore_over_socket
kvstore_over_socket_reorder