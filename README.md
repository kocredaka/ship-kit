# Fuji-to-C-Chain Ship Kit

A minimal, runnable Foundry starter for shipping your first contract on
Avalanche: build and test locally, deploy to the **Fuji testnet for free**,
verify on Snowtrace, then promote the same code to **C-Chain mainnet** with a
checklist. No mainnet funds are needed to complete the Fuji walkthrough.

Built for new Avalanche builders. C-Chain is EVM-compatible (a go-ethereum
fork called Coreth), so standard Ethereum tooling works unchanged — only the
network config differs.

> **Status:** Deployed live on Fuji testnet (chain 43113) on 15 Nov 2026:
> Greeter `0xa4B0f239aDAaeD6defB6cfC63E8FE7C11BA28599` and ShipKitRegistry
> `0xd8638518D48136c0C5F790283e876E38134fa421`, both Sourcify exact_match,
> with a shipment recorded in the registry (see `broadcast/` for receipts).
> No contract has been deployed to mainnet. Contracts are demo/reference
> code with **no third-party audit**.
>
> **Setup note:** this repo carries no vendored dependencies. After cloning,
> run `forge install foundry-rs/forge-std --no-commit` once (or clone with
> `--recursive`) so `lib/forge-std` exists before `forge build`.

## What's inside

| Path | What it is |
|---|---|
| `src/ShipKitRegistry.sol` | On-chain registry: record contracts you shipped (name, address, chain, metadata). Non-custodial, holds no funds. |
| `src/Greeter.sol` | Smallest useful demo contract: one message, owner-only updates. |
| `script/DeployRegistry.s.sol` | Deploy the registry (Fuji or C-Chain, via `--rpc-url`). |
| `script/DeployGreeter.s.sol` | Deploy the Greeter demo (set `GREETER_MESSAGE` to change the greeting). |
| `test/` | 18 Foundry tests (unit + fuzz) for both contracts. |
| `checker/preflight.sh` | Pre-deploy checks: build, bytecode size, RPC + chain ID, deployer balance, verification key. |
| `checker/verify.sh` | Snowtrace source verification wrapper. |
| `guides/FUJI-QUICKSTART.md` | Fuji from zero: wallet, faucet, deploy, verify, record — in ~30 minutes. |
| `guides/CCHAIN-CHECKLIST.md` | Mainnet promotion checklist (gas, safety, verification). |

## Quick start (local, no funds)

Prerequisites: [Foundry](https://getfoundry.sh) (`forge`, `cast`, `anvil`).

```shell
git clone <this-repo> ship-kit
cd ship-kit
forge build
forge test
```

Run the whole flow against a local node (chain ID 43113, like Fuji):

```shell
anvil --chain-id 43113 --port 8545   # terminal 1

# terminal 2 — the key below is Anvil's well-known PUBLIC test key #0.
# Local testing only. NEVER use it on any live network.
export PRIVATE_KEY=$(cast wallet private-key \
  --mnemonic "test test test test test test test test test test test junk" \
  --mnemonic-index 0)

RPC_URL=http://127.0.0.1:8545 EXPECTED_CHAIN_ID=43113 ./checker/preflight.sh custom

forge script script/DeployGreeter.s.sol  --rpc-url http://127.0.0.1:8545 --broadcast
forge script script/DeployRegistry.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

Then interact with `cast` (replace the addresses with your deploy output):

```shell
GREETER=<greeter-address>
REGISTRY=<registry-address>
RPC=http://127.0.0.1:8545

cast send $GREETER "setMessage(string)" "hello, fuji" \
  --private-key $PRIVATE_KEY --rpc-url $RPC
cast call $GREETER "message()(string)" --rpc-url $RPC

cast send $REGISTRY "recordShipment(address,string,string)" \
  $GREETER "greeter-demo" "ship-kit e2e" \
  --private-key $PRIVATE_KEY --rpc-url $RPC
cast call $REGISTRY "getShipment(address)((address,address,uint256,string,string,uint64))" \
  $GREETER --rpc-url $RPC
```

## Fuji testnet (free)

Follow [`guides/FUJI-QUICKSTART.md`](guides/FUJI-QUICKSTART.md): generate a fresh
throwaway key, claim 2 test AVAX from the official faucet (browser + CAPTCHA),
run preflight, deploy, verify on Snowtrace, and record your shipment.

```shell
cp .env.example .env   # fill in PRIVATE_KEY (throwaway key only)
./checker/preflight.sh fuji
forge script script/DeployGreeter.s.sol --rpc-url $FUJI_RPC_URL --broadcast
```

## C-Chain mainnet

Do **not** deploy to mainnet until you have read
[`guides/CCHAIN-CHECKLIST.md`](guides/CCHAIN-CHECKLIST.md). Mainnet costs real
AVAX. The deploy commands are identical except for the RPC URL — the checklist
exists so the promotion is deliberate, not accidental.

## Configuration

| Variable | Purpose |
|---|---|
| `PRIVATE_KEY` | Deployer key. **Never commit a real key.** Use a fresh throwaway key for Fuji. |
| `FUJI_RPC_URL` | Fuji C-Chain RPC (default in `foundry.toml` is the public endpoint). |
| `CCHAIN_RPC_URL` | C-Chain mainnet RPC (default in `foundry.toml` is the public endpoint). |
| `SNOWTRACE_API_KEY` | Free key from snowtrace.io, for `forge verify-contract`. |
| `GREETER_MESSAGE` | Optional greeting for the Greeter demo deploy. |

`foundry.toml` already declares the public RPC endpoints (`fuji`, `cchain`) and
the Snowtrace verification config, so `--rpc-url fuji` also works with
`forge script` once `PRIVATE_KEY` is set.

## Design notes

- **ShipKitRegistry is deliberately boring.** It stores records, moves no
  funds, and has no admin role. Recording requires the address to contain code
  (`extcodesize > 0`) and a non-empty name; only the original deployer can
  update a record's metadata. Records are per-chain (keyed by `block.chainid`),
  so the same registry code deployed on Fuji and C-Chain keeps separate state.
- **No upgradeability, no proxies, no dependencies** beyond `forge-std` (tests
  only). The contracts compile with solc 0.8.24, optimizer on, 200 runs.
- **Security posture:** demo/reference code, no audit. Do not store secrets,
  do not send funds to these contracts, and do not copy the registry pattern
  into anything holding value without an independent review.

## License

MIT — see [`LICENSE`](LICENSE). `forge-std` (in `lib/`, tests only) is MIT
licensed by its own authors.
