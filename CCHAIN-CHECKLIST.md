# C-Chain mainnet checklist — promote deliberately, not accidentally

Deploying to C-Chain mainnet (chain ID 43114) spends **real AVAX** and is
**irreversible**. Complete every item before broadcasting. If any item is
unchecked, stay on Fuji.

## Before you deploy

- [ ] **Fuji first, fully green.** The exact code (same commit, same compiler
      settings) is deployed, verified, and exercised on Fuji. No "quick
      mainnet-only fixes".
- [ ] **Tests pass.** `forge test` is green, including fuzz tests. Known
      limitations are written down, not assumed away.
- [ ] **You understand every line you deploy.** No pasted code you cannot
      explain. No unaudited code holding user funds — ever.
- [ ] **No secrets in the repo.** `PRIVATE_KEY` is in `.env` (gitignored),
      never committed. Run `git log -p | grep -i private` if unsure.
- [ ] **Dedicated deployer wallet.** A fresh wallet funded with only the AVAX
      needed for deployment. Never deploy from a wallet holding significant
      funds.
- [ ] **Gas budgeted.** Estimate with a dry run first:
      `forge script script/<Script>.s.sol --rpc-url cchain` (no `--broadcast`),
      then check the printed gas estimate. Fund the deployer with a margin
      above it — and nothing more.
- [ ] **Constructor args double-checked.** Wrong constructor args = a redeploy
      (and more gas). Print them, read them, then broadcast.
- [ ] **Preflight passes against mainnet.**
      `./checker/preflight.sh cchain` must report chain ID 43114 and a
      non-zero balance. Read its mainnet warning and confirm you mean it.

## Deploy

```shell
./checker/preflight.sh cchain
forge script script/DeployGreeter.s.sol --rpc-url cchain --broadcast
```

Record the deployed address and transaction hash immediately. Keep the
`broadcast/` log — it is your audit trail.

## After you deploy

- [ ] **Verify on Snowtrace** (mainnet): `./checker/verify.sh cchain <address> <Contract> [args...]`
      Unverified mainnet contracts are hard for anyone (including you, later)
      to trust or debug.
- [ ] **Read-back check.** Call every view function with `cast call` and
      confirm the deployed state matches your intent (owner, parameters,
      initial values).
- [ ] **Small interaction first.** Exercise one state-changing function with
      minimal value before announcing anything.
- [ ] **Record the shipment** in your registry deployment (if you run one),
      with accurate metadata and a link to the verified source.
- [ ] **Monitor.** Watch the first hours of activity. Know how you would
      respond to unexpected behavior (pause? migrate? communicate?) *before*
      you need to.

## Never

- Never deploy unaudited code that holds or moves other people's funds.
- Never reuse a testnet throwaway key on mainnet.
- Never broadcast from a script you have not dry-run on Fuji first.
- Never promise users anything about a contract you have not verified
  on Snowtrace.
