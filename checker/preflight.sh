#!/usr/bin/env bash
# preflight.sh — pre-deploy checks for the Fuji-to-C-Chain Ship Kit.
#
# Usage:
#   ./checker/preflight.sh fuji          # check against Fuji testnet (chain 43113)
#   ./checker/preflight.sh cchain        # check against C-Chain mainnet (chain 43114)
#   RPC_URL=<url> EXPECTED_CHAIN_ID=<id> ./checker/preflight.sh custom
#
# Checks (fails fast, exit code 1, with a clear message):
#   1. forge + cast are installed
#   2. project builds (forge build)
#   3. creation bytecode of every src contract is under the 24,576-byte limit
#   4. RPC endpoint is reachable and reports the expected chain ID
#   5. deployer key resolves to an address with a non-zero balance
#   6. (warning only) SNOWTRACE_API_KEY is set, for contract verification
#
# The deployer key is read from PRIVATE_KEY (env var or .env file).
# NEVER commit a real private key. For Fuji, use a fresh throwaway key.
set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="${1:-fuji}"
case "$TARGET" in
  fuji)   RPC_URL="${RPC_URL:-https://api.avax-test.network/ext/bc/C/rpc}"; EXPECTED_CHAIN_ID=43113 ;;
  cchain) RPC_URL="${RPC_URL:-https://api.avax.network/ext/bc/C/rpc}";     EXPECTED_CHAIN_ID=43114 ;;
  custom) RPC_URL="${RPC_URL:?RPC_URL must be set for target 'custom'}";    EXPECTED_CHAIN_ID="${EXPECTED_CHAIN_ID:?EXPECTED_CHAIN_ID must be set for target 'custom'}" ;;
  *) echo "Usage: $0 {fuji|cchain|custom}" >&2; exit 2 ;;
esac

# Load .env if present (without overriding exported vars).
if [ -f .env ]; then set -a; # shellcheck disable=SC1091
  . ./.env; set +a
fi

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "  OK: $*"; }

echo "Ship Kit preflight — target: $TARGET (chain $EXPECTED_CHAIN_ID)"
echo "RPC: $RPC_URL"

# 1. Toolchain
command -v forge >/dev/null || fail "forge not found — install Foundry: https://getfoundry.sh"
command -v cast  >/dev/null || fail "cast not found — install Foundry: https://getfoundry.sh"
ok "forge + cast installed ($(forge --version | head -1))"

# 2. Build
forge build --silent || fail "forge build failed — fix compile errors first"
ok "project builds"

# 3. Bytecode size (EIP-170: max 24,576 bytes of deployed code).
python3 - "$PWD/out" <<'PY'
import json, pathlib, sys
out = pathlib.Path(sys.argv[1])
limit = 24576
bad = []
for artifact in sorted(out.rglob("*.json")):
    try:
        data = json.loads(artifact.read_text())
    except Exception:
        continue
    deployed = (data.get("deployedBytecode") or {}).get("object") or ""
    size = (len(deployed) - 2) // 2 if deployed.startswith("0x") else len(deployed) // 2
    name = data.get("ast", {}).get("absolutePath", artifact.name)
    if size > 0:
        print(f"  bytecode: {artifact.stem} deployed={size} bytes")
    if size > limit:
        bad.append((artifact.stem, size))
if bad:
    for name, size in bad:
        print(f"FAIL: {name} deployed bytecode {size} bytes exceeds {limit}", file=sys.stderr)
    sys.exit(1)
PY
ok "all deployed bytecodes under 24,576 bytes"

# 4. RPC reachable + chain ID matches
CHAIN_ID="$(cast chain-id --rpc-url "$RPC_URL" 2>/dev/null)" || fail "RPC unreachable: $RPC_URL"
[ "$CHAIN_ID" = "$EXPECTED_CHAIN_ID" ] || fail "chain ID mismatch: RPC reports $CHAIN_ID, expected $EXPECTED_CHAIN_ID"
ok "RPC reachable, chain ID $CHAIN_ID"

# 5. Deployer key + balance
[ -n "${PRIVATE_KEY:-}" ] || fail "PRIVATE_KEY is not set (env var or .env). For Fuji, generate a fresh throwaway key: cast wallet new"
DEPLOYER="$(cast wallet address --private-key "$PRIVATE_KEY" 2>/dev/null)" || fail "PRIVATE_KEY is not a valid private key"
BALANCE_WEI="$(cast balance "$DEPLOYER" --rpc-url "$RPC_URL" 2>/dev/null)" || fail "could not read balance for $DEPLOYER"
[ "$BALANCE_WEI" != "0" ] || fail "deployer $DEPLOYER has zero balance on chain $EXPECTED_CHAIN_ID — fund it first (Fuji: free faucet, see guides/FUJI-QUICKSTART.md)"
BALANCE_AVAX="$(cast --to-unit "$BALANCE_WEI" ether)"
ok "deployer $DEPLOYER balance: $BALANCE_AVAX AVAX"

# 6. Verification key (warning only)
if [ -z "${SNOWTRACE_API_KEY:-}" ]; then
  echo "  WARN: SNOWTRACE_API_KEY not set — 'forge verify-contract' will be skipped (deploy still works)"
else
  ok "SNOWTRACE_API_KEY set (verification available)"
fi

if [ "$TARGET" = "cchain" ]; then
  echo "  WARN: target is MAINNET — real AVAX will be spent. Re-read guides/CCHAIN-CHECKLIST.md before broadcasting."
fi

echo "Preflight PASSED for $TARGET."
