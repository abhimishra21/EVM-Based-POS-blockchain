#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_DIR="${BASE_DIR:-${ROOT_DIR}/.localnet}"
NODE_COUNT="${NODE_COUNT:-3}"

for i in $(seq 0 $((NODE_COUNT - 1))); do
  PID_FILE="${BASE_DIR}/node${i}.pid"
  if [[ -f "${PID_FILE}" ]]; then
    PID="$(cat "${PID_FILE}")"
    if kill -0 "${PID}" 2>/dev/null; then
      echo "Stopping node${i} (${PID})..."
      kill "${PID}"
    fi
    rm -f "${PID_FILE}"
  fi
done

echo "Stop signal sent to localnet nodes."
