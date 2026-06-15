#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARY="${ROOT_DIR}/bin/mychaind"
CHAIN_ID="${CHAIN_ID:-mychain-localnet-1}"
NODE_COUNT="${NODE_COUNT:-3}"
BASE_DIR="${BASE_DIR:-${ROOT_DIR}/.localnet}"
DENOM="${DENOM:-stake}"
P2P_BASE_PORT="${P2P_BASE_PORT:-27656}"
RPC_BASE_PORT="${RPC_BASE_PORT:-26657}"
API_BASE_PORT="${API_BASE_PORT:-1317}"
GRPC_BASE_PORT="${GRPC_BASE_PORT:-19090}"
PPROF_BASE_PORT="${PPROF_BASE_PORT:-6060}"
PROM_BASE_PORT="${PROM_BASE_PORT:-26660}"

if [[ "${NODE_COUNT}" -lt 1 ]]; then
  echo "NODE_COUNT must be at least 1" >&2
  exit 1
fi

mkdir -p "${ROOT_DIR}/bin"

echo "Building mychaind..."
(cd "${ROOT_DIR}" && go build -o "${BINARY}" ./cmd/mychaind)

echo "Resetting ${BASE_DIR}..."
rm -rf "${BASE_DIR}"
mkdir -p "${BASE_DIR}"

declare -a ADDRESSES

for i in $(seq 0 $((NODE_COUNT - 1))); do
  HOME_DIR="${BASE_DIR}/node${i}"
  MONIKER="node${i}"

  echo "Initializing ${MONIKER}..."
  "${BINARY}" init "${MONIKER}" --chain-id "${CHAIN_ID}" --home "${HOME_DIR}" >/dev/null

  "${BINARY}" keys add "${MONIKER}" --keyring-backend test --home "${HOME_DIR}" >/dev/null 2>&1
  ADDRESSES[$i]="$("${BINARY}" keys show "${MONIKER}" -a --keyring-backend test --home "${HOME_DIR}")"
  "${BINARY}" genesis add-genesis-account "${MONIKER}" "1000000000${DENOM}" --keyring-backend test --home "${HOME_DIR}"
  "${BINARY}" genesis gentx "${MONIKER}" "1000000${DENOM}" --chain-id "${CHAIN_ID}" --keyring-backend test --home "${HOME_DIR}" >/dev/null
done

for i in $(seq 1 $((NODE_COUNT - 1))); do
  "${BINARY}" genesis add-genesis-account "${ADDRESSES[$i]}" "1000000000${DENOM}" --home "${BASE_DIR}/node0"
done

for i in $(seq 1 $((NODE_COUNT - 1))); do
  cp "${BASE_DIR}/node${i}/config/gentx/"*.json "${BASE_DIR}/node0/config/gentx/"
done

echo "Collecting gentxs..."
"${BINARY}" genesis collect-gentxs --home "${BASE_DIR}/node0" >/dev/null

GENESIS_FILE="${BASE_DIR}/node0/config/genesis.json"

for i in $(seq 1 $((NODE_COUNT - 1))); do
  cp "${GENESIS_FILE}" "${BASE_DIR}/node${i}/config/genesis.json"
done

declare -a NODE_IDS
for i in $(seq 0 $((NODE_COUNT - 1))); do
  NODE_IDS[$i]="$("${BINARY}" comet show-node-id --home "${BASE_DIR}/node${i}")"
done

for i in $(seq 0 $((NODE_COUNT - 1))); do
  HOME_DIR="${BASE_DIR}/node${i}"
  CONFIG_FILE="${HOME_DIR}/config/config.toml"
  APP_FILE="${HOME_DIR}/config/app.toml"

  P2P_PORT=$((P2P_BASE_PORT + i))
  RPC_PORT=$((RPC_BASE_PORT + i))
  API_PORT=$((API_BASE_PORT + i))
  GRPC_PORT=$((GRPC_BASE_PORT + i))
  PPROF_PORT=$((PPROF_BASE_PORT + i))
  PROM_PORT=$((PROM_BASE_PORT + i))

  PEERS=""
  if [[ "${i}" -gt 0 ]]; then
    PEERS="${NODE_IDS[0]}@127.0.0.1:${P2P_BASE_PORT}"
  fi

  sed -i.bak \
    -e "s#^moniker = .*#moniker = \"node${i}\"#" \
    -e "s#^persistent_peers = .*#persistent_peers = \"${PEERS}\"#" \
    -e "s#^laddr = \"tcp://127.0.0.1:26657\"#laddr = \"tcp://127.0.0.1:${RPC_PORT}\"#" \
    -e "s#^pprof_laddr = .*#pprof_laddr = \"localhost:${PPROF_PORT}\"#" \
    -e "s#^prometheus_listen_addr = .*#prometheus_listen_addr = \":${PROM_PORT}\"#" \
    -e "s#^addr_book_strict = .*#addr_book_strict = false#" \
    -e "s#^allow_duplicate_ip = .*#allow_duplicate_ip = true#" \
    -e "s#^pex = .*#pex = false#" \
    "${CONFIG_FILE}"

  sed -i.bak \
    -e "s#^laddr = \"tcp://0.0.0.0:26656\"#laddr = \"tcp://0.0.0.0:${P2P_PORT}\"#" \
    "${CONFIG_FILE}"

  sed -i.bak \
    -e "s#^minimum-gas-prices = .*#minimum-gas-prices = \"0${DENOM}\"#" \
    -e "s#^address = \"tcp://localhost:1317\"#address = \"tcp://127.0.0.1:${API_PORT}\"#" \
    -e "s#^address = \"localhost:9090\"#address = \"127.0.0.1:${GRPC_PORT}\"#" \
    "${APP_FILE}"
done

cat <<EOF
Initialized ${NODE_COUNT} local nodes under:
  ${BASE_DIR}

Next:
  ${ROOT_DIR}/scripts/localnet-start.sh

RPC endpoints:
$(for i in $(seq 0 $((NODE_COUNT - 1))); do echo "  node${i}: http://127.0.0.1:$((RPC_BASE_PORT + i))"; done)
EOF
