#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARY="${ROOT_DIR}/bin/mychaind"
BASE_DIR="${BASE_DIR:-${ROOT_DIR}/.localnet}"
NODE_COUNT="${NODE_COUNT:-3}"
LOG_DIR="${BASE_DIR}/logs"

if [[ ! -x "${BINARY}" ]]; then
  echo "Binary not found at ${BINARY}. Run scripts/localnet-init.sh first." >&2
  exit 1
fi

mkdir -p "${LOG_DIR}"

for i in $(seq 0 $((NODE_COUNT - 1))); do
  HOME_DIR="${BASE_DIR}/node${i}"
  LOG_FILE="${LOG_DIR}/node${i}.log"
  PID_FILE="${BASE_DIR}/node${i}.pid"

  if [[ ! -d "${HOME_DIR}" ]]; then
    echo "Missing ${HOME_DIR}. Run scripts/localnet-init.sh first." >&2
    exit 1
  fi

  echo "Starting node${i}..."
  nohup "${BINARY}" start --home "${HOME_DIR}" >"${LOG_FILE}" 2>&1 &
  echo $! >"${PID_FILE}"
done

echo "Started ${NODE_COUNT} nodes."
echo "Logs:"
for i in $(seq 0 $((NODE_COUNT - 1))); do
  echo "  node${i}: ${LOG_DIR}/node${i}.log"
done
echo "RPC:"
for i in $(seq 0 $((NODE_COUNT - 1))); do
  echo "  node${i}: http://127.0.0.1:$((26657 + i))"
done
