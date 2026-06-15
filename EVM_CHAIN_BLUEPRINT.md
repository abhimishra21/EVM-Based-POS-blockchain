# EVM-Compatible Chain Blueprint

This repository is the Cosmos SDK itself, not an EVM chain implementation.
The cleanest path to "your own blockchain compatible with EVM" is:

1. Use this repo to understand and reuse the standard Cosmos SDK app structure.
2. Use `simapp` as the local reference for app wiring.
3. Integrate the external `github.com/cosmos/evm` modules and configuration into a new app.

## What this repository already gives you

The main building blocks for a sovereign Cosmos chain are already here:

- `simapp/app.go`: a complete example Cosmos SDK application
- `simapp/simd/main.go`: a runnable node binary entrypoint
- `baseapp/`: ABCI application plumbing
- `x/auth`, `x/bank`, `x/staking`, `x/gov`, `x/slashing`, `x/distribution`, `x/upgrade`: the standard chain modules
- `client/` and `server/`: CLI, config, and node plumbing

`simapp` is the best in-repo template because it already shows:

- keeper construction
- store key registration
- module manager setup
- begin/end/pre-block ordering
- ante/post-handler setup
- genesis initialization

## What is missing for EVM compatibility

This repo does not wire an EVM runtime into `simapp`.
For EVM compatibility you still need Cosmos EVM pieces from `github.com/cosmos/evm`, including:

- the EVM execution module
- the fee market module
- Ethereum JSON-RPC server support
- `eth_secp256k1` key support
- Ethereum-style address derivation and coin type `60`
- EVM-specific ante handling and, if desired, the EVM mempool

## Recommended architecture

Create a new application instead of modifying `simapp` directly. A practical layout is:

```text
mychain/
  app/
    app.go
    ante.go
    encoding.go
    config.go
    genesis.go
  cmd/mychaind/
    main.go
    root.go
  x/
    <your custom modules>
```

Use the current `simapp` wiring as the baseline, then add Cosmos EVM integration on top.

## How to map `simapp` to your chain

### 1. Start from the app shell

Use these parts of `simapp/app.go` as the skeleton:

- app struct and core fields
- `NewSimApp(...)`
- keeper creation flow
- module manager registration
- block order configuration
- `InitChainer`, `BeginBlocker`, `EndBlocker`, `PreBlocker`

The most important local references are:

- `simapp/app.go`
- `simapp/simd/main.go`
- `simapp/README.md`

### 2. Replace Cosmos account assumptions with Ethereum-compatible ones

Before adding the EVM module, your chain should adopt Ethereum-oriented account settings:

- set SDK coin type to `60`
- support `eth_secp256k1`
- use address/signing config that preserves Ethereum-compatible account derivation

Why this matters:

- the same mnemonic should map cleanly to EVM tooling
- MetaMask and similar wallets expect Ethereum derivation behavior
- users should be able to work with both `0x...` and Bech32 forms of the same underlying account

### 3. Add EVM and fee market keepers

In your app struct, plan for at least:

- standard SDK keepers from `simapp`
- EVM keeper
- fee market keeper
- optional ERC-20 / precompile-related keepers if your product needs them

You will also need to add their store keys and module registration entries alongside the existing `simapp` modules.

### 4. Replace the default ante handler

`simapp` currently uses the standard Cosmos SDK auth ante flow in `setAnteHandler`.
An EVM chain needs an ante path that understands:

- Ethereum transaction formats
- EIP-155 / replay protection
- EIP-1559 fee handling
- Ethereum signature verification
- nonce handling compatible with EVM accounts

This is one of the most important differences between a normal Cosmos app and an EVM-compatible one.

### 5. Expose Ethereum JSON-RPC

An EVM chain is not "EVM-compatible" in the practical sense unless tooling can connect through Ethereum RPC APIs.
That means your node configuration must expose JSON-RPC namespaces such as:

- `eth`
- `net`
- `web3`
- `txpool`
- optionally `debug`

### 6. Configure chain economics for EVM usage

Decide early:

- native gas token denom
- whether the token uses 18 decimals
- EVM chain ID
- block gas limits
- fee market defaults

This affects wallets, fee estimation, genesis settings, and migration complexity later.

## Concrete implementation plan

### Phase 1: Create your custom chain shell

1. Copy the structure of `simapp` into a new app package and binary.
2. Rename app constants, default home dir, and binary names.
3. Keep the standard Cosmos modules working first.
4. Verify the new non-EVM chain boots locally before adding EVM.

### Phase 2: Make accounts EVM-ready

1. Set coin type `60`.
2. Add `eth_secp256k1` support in keyring/signing configuration.
3. Verify new keys can be created for Ethereum-style usage.

### Phase 3: Integrate Cosmos EVM

1. Add Cosmos EVM dependencies.
2. Wire EVM and fee market keepers into the app.
3. Register modules, genesis state, and module ordering.
4. Replace the ante handler with the EVM-aware flow.
5. Enable JSON-RPC and EVM config in `app.toml`.

### Phase 4: Validate developer experience

1. Start the chain locally.
2. Connect MetaMask or Foundry to your JSON-RPC endpoint.
3. Deploy a trivial Solidity contract.
4. Send a value transfer and verify receipts and balances.

## Minimal acceptance checklist

Your chain is "really" EVM-compatible only when all of these work:

- node starts successfully
- JSON-RPC is enabled
- an `eth_secp256k1` account can sign transactions
- `eth_chainId` returns your configured EVM chain ID
- a Solidity contract deploys successfully
- `eth_call`, `eth_sendRawTransaction`, and `eth_getTransactionReceipt` work
- wallets like MetaMask can connect without custom hacks

## Important gotchas

- Do not hand-edit generated files.
- Do not manually edit `go.sum`.
- Do not treat `simapp` as production-ready chain code; it is a teaching and test app.
- Do not postpone account-derivation decisions. Address derivation mistakes are expensive to fix later.
- Do not call a chain EVM-compatible if it lacks Ethereum JSON-RPC support.

## Best starting point

If your main goal is to launch quickly, the best base is not this repo alone.
It is:

1. Cosmos SDK concepts and app wiring from this repository
2. the `evmd` reference implementation from `github.com/cosmos/evm`

If your main goal is learning, start by reading:

- `simapp/app.go`
- `simapp/simd/main.go`
- `x/README.md`
- `README.md`

## Sources

Local repository:

- `README.md`
- `x/README.md`
- `simapp/app.go`
- `simapp/simd/main.go`
- `simapp/README.md`

Official external references:

- Cosmos EVM repository: <https://github.com/cosmos/evm>
- Cosmos EVM overview: <https://docs.cosmos.network/evm/latest/documentation/overview>
- Cosmos EVM local network setup: <https://evm.cosmos.network/docs/evm/next/documentation/getting-started/local-network-setup>
- Adding EVM to an existing chain: <https://docs.cosmos.network/evm/latest/documentation/migrations/add-evm-to-existing-chain>
