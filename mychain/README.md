# MyChain

`mychain` is a starter blockchain scaffold built on top of the Cosmos SDK `simapp`.

Today it gives you:

- your own Go module: `cosmossdk.io/mychain`
- your own binary: `mychaind`
- your own default home directory: `~/.mychain`
- your own command package and app wrapper

It still uses `simapp` under the hood, which makes it a safe starting point for customization.

## Build

From the repo root:

```bash
cd mychain
go build ./cmd/mychaind
```

## Initialize a local chain

```bash
cd mychain
go run ./cmd/mychaind init mynode --chain-id mychain-local-1
```

## Create a key

```bash
cd mychain
go run ./cmd/mychaind keys add alice
```

## Next customization steps

1. Rename `MyChain` and `mychaind` to your real chain name.
2. Change the staking and fee denom from `stake`.
3. Replace the thin `simapp` wrapper with your own app wiring over time.
4. Add custom modules or integrate Cosmos EVM if you want Solidity and Ethereum RPC support.

## Run 3 local nodes

Initialize a 3-node local network:

```bash
cd /home/akmishra/Desktop/icp/cosmos-sdk/mychain
./scripts/localnet-init.sh
```
 
Start the nodes:

```bash
./scripts/localnet-start.sh
```

Stop the nodes:

```bash
./scripts/localnet-stop.sh
```

Default RPC endpoints:

- `node0`: `http://127.0.0.1:26657`
- `node1`: `http://127.0.0.1:26658`
- `node2`: `http://127.0.0.1:26659`

Useful overrides:

```bash
CHAIN_ID=mychain-dev-1 NODE_COUNT=3 ./scripts/localnet-init.sh
BASE_DIR=/tmp/mychain-localnet ./scripts/localnet-start.sh
```
