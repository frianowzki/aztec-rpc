#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install jq to run this script."
    exit 1
fi

echo "=== GETH SYNC STATUS ==="
geth_sync=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
     -H "Content-Type: application/json" http://localhost:8545)

if [[ "$geth_sync" == "false" ]]; then
    echo "Geth is fully synced."
else
    echo "$geth_sync" | jq
fi

echo ""
echo "=== BEACON SYNC STATUS ==="
beacon_sync=$(curl -s http://localhost:3500/eth/v1/node/syncing)

if [[ -z "$beacon_sync" ]]; then
    echo "Beacon node sync status not available or beacon node not reachable."
else
    echo "$beacon_sync" | jq
fi
