# Fuji quickstart — deploy your first contract for free (~30 minutes)

Goal: a contract live on the Fuji testnet, verified on Snowtrace, with your
shipment recorded in the ShipKitRegistry. Everything here uses **testnet**
AVAX, which has no value. No mainnet funds, no payment, no account signup
beyond a free Snowtrace API key (optional, for verification).

## 0. Prerequisites

- Foundry installed (`forge`, `cast`): https://getfoundry.sh
- A browser (the faucet requires a CAPTCHA — it cannot be claimed from a
  plain script).

## 1. Generate a fresh throwaway key

```shell
cast wallet new
```

Save the address and private key somewhere local and temporary (for example
your shell history or a local `.env` — never in git, never in a chat).
**This key is for Fuji only.** Never reuse it on mainnet, and never send it
real funds.

```shell
cp .env.example .env
# Edit .env: paste the private key as PRIVATE_KEY (with or without 0x prefix).
```

## 2. Claim 2 test AVAX from the official faucet

1. Open https://faucet.avax.network in your browser.
2. Select **Fuji (C-Chain)**.
3. Paste your new address, complete the CAPTCHA, click **Request 2 AVAX**.
4. Wait 10–60 seconds, then confirm the balance:

```shell
cast balance <your-address> --rpc-url https://api.avax-test.network/ext/bc/C/rpc
```

Limits (as documented by the faucet): 2 AVAX per request, 1 request per
24 hours per address and per IP. 2 AVAX covers hundreds of Fuji transactions.

**If the faucet is rate-limited or unavailable:** the Avalanche Discord
(`#faucet` channel, `!faucet <address>`) is the documented fallback; it
requires a verified Discord account. Do not pay anyone for test AVAX.

## 3. Preflight

```shell
./checker/preflight.sh fuji
```

This checks: the project builds, bytecodes fit the size limit, the RPC is
reachable and reports chain ID 43113, and your deployer address has a
non-zero balance. Fix anything it reports before continuing.

## 4. Deploy

```shell
forge script script/DeployGreeter.s.sol --rpc-url fuji --broadcast
forge script script/DeployRegistry.s.sol --rpc-url fuji --broadcast
```

Note the deployed addresses from the output (they also land in
`broadcast/Deploy*.s.sol/43113/run-latest.json`).

## 5. Verify on Snowtrace (optional but recommended)

Get a free API key at https://snowtrace.io/apis, set `SNOWTRACE_API_KEY`
in `.env`, then:

```shell
./checker/verify.sh fuji <greeter-address> Greeter "hello, avalanche"
./checker/verify.sh fuji <registry-address> ShipKitRegistry
```

(Constructor args must match what you deployed with. For Greeter, that is
the greeting string; the registry takes none.)

Check the result at `https://testnet.snowtrace.io/address/<address>` — the
contract tab should show the verified source.

## 6. Record your shipment

```shell
cast send <registry-address> "recordShipment(address,string,string)" \
  <greeter-address> "greeter-demo" "first Fuji deploy via Ship Kit" \
  --private-key $PRIVATE_KEY --rpc-url fuji

cast call <registry-address> \
  "getShipment(address)((address,address,uint256,string,string,uint64))" \
  <greeter-address> --rpc-url fuji
```

You should see your deployer address, the contract address, chain ID 43113,
the name, and the metadata. Congratulations — you shipped on Avalanche.

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| `PRIVATE_KEY is not set` | `.env` missing or not loaded; `cp .env.example .env` and fill it in. |
| `deployer has zero balance` | Faucet drip has not arrived yet (wait a minute) or the address in `.env` differs from the one you funded. |
| `chain ID mismatch` | Wrong RPC URL — Fuji is 43113, C-Chain mainnet is 43114. Check `foundry.toml`. |
| `Failed to decode private key` | The key is not 64 hex characters. Re-copy it, or regenerate with `cast wallet new`. Never hand-type a key. |
| Verification fails with "already verified" | The contract (or identical bytecode) is already verified — that is fine. |
| `nonce too low` / stuck tx | A previous broadcast used the same nonce; wait for the pending tx or use `--resume`. |

## What not to do

- Do not paste your private key into any website, chat, or form.
- Do not use your Fuji throwaway key on mainnet.
- Do not treat Fuji state as permanent — testnets can be reset.
