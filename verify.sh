#!/usr/bin/env bash
# verify.sh — verify a deployed contract's source on Snowtrace.
#
# Usage:
#   ./checker/verify.sh fuji <contract-address> <ContractName> [constructor-args...]
#   ./checker/verify.sh cchain <contract-address> <ContractName> [constructor-args...]
#
# Example (Greeter with its constructor message):
#   ./checker/verify.sh fuji 0xYourGreeterAddress Greeter "hello, avalanche"
#
# Requires SNOWTRACE_API_KEY (free key from snowtrace.io). Reads .env if present.
set -euo pipefail

cd "$(dirname "$0")/.."

[ $# -ge 3 ] || { echo "Usage: $0 {fuji|cchain} <address> <ContractName> [constructor-args...]" >&2; exit 2; }
TARGET="$1"; ADDRESS="$2"; CONTRACT="$3"; shift 3

case "$TARGET" in
  fuji)   RPC_URL="${RPC_URL:-https://api.avax-test.network/ext/bc/C/rpc}"; ETHERSCAN_KEY_NAME="SNOWTRACE_API_KEY" ;;
  cchain) RPC_URL="${RPC_URL:-https://api.avax.network/ext/bc/C/rpc}";     ETHERSCAN_KEY_NAME="SNOWTRACE_API_KEY" ;;
  *) echo "Target must be fuji or cchain" >&2; exit 2 ;;
esac

if [ -f .env ]; then set -a; # shellcheck disable=SC1091
  . ./.env; set +a
fi

[ -n "${SNOWTRACE_API_KEY:-}" ] || { echo "FAIL: SNOWTRACE_API_KEY is not set (env var or .env). Get a free key at https://snowtrace.io/apis" >&2; exit 1; }

ARGS=()
if [ $# -gt 0 ]; then
  ARGS=(--constructor-args "$@")
fi

forge verify-contract \
  --rpc-url "$RPC_URL" \
  --etherscan-api-key "$SNOWTRACE_API_KEY" \
  --chain "$TARGET" \
  "$ADDRESS" \
  "src/${CONTRACT}.sol:${CONTRACT}" \
  "${ARGS[@]}"

echo "Verification submitted for $CONTRACT at $ADDRESS on $TARGET."
echo "Check status on Snowtrace: https://snowtrace.io/address/$ADDRESS (mainnet) or https://testnet.snowtrace.io/address/$ADDRESS (Fuji)"
