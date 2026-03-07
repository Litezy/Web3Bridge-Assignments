# 🏦 Vault Factory — Onchain ERC20 Vaults with Dynamic NFTs

A Solidity smart contract system that deploys dedicated ERC20 token vaults via a factory pattern, with each vault minted an onchain dynamic NFT at deployment.

---

## How It Works

The **Factory** contract is the entry point. An admin calls `deployVault(token)` to spin up a new child vault dedicated to a specific ERC20 token. At the moment of deployment, the factory mints a dynamic NFT and attaches it to the vault contract. Users can then deposit and withdraw tokens directly through the vault.

```
Admin → Factory.deployVault(token)
             │
             ├── deploys TokenVault (CREATE2)
             └── mints NFT → attached to vault
                       │
                  Users → Vault.deposit(amount)
                        → Vault.withdraw(amount)
```

---

## Contracts

| Contract | Description |
|---|---|
| `Factory.sol` | Deploys vaults via CREATE2, mints NFTs, tracks vault addresses |
| `TokenVault.sol` | Holds ERC20 deposits per user, generates onchain NFT art |
| `VaultNFT.sol` | ERC721 contract, reads live vault state for dynamic metadata |

---

## Features

- **One vault per token** — each ERC20 gets its own dedicated vault
- **CREATE2 deployment** — vault addresses are deterministic and predictable before deployment
- **Dynamic onchain NFT** — SVG art generated live from vault state, balance updates reflected automatically
- **No IPFS** — fully onchain metadata and artwork
- **Mainnet fork tested** — tested against real USDC, DAI, WETH on a mainnet fork

---

## Usage

```solidity
// predict vault address before deploying
address predicted = factory.computeVaultAddress(USDC);

// deploy vault — mints NFT to vault
factory.deployVault(USDC);

// deposit into vault (approve first)
IERC20(USDC).approve(vaultAddress, amount);
TokenVault(vaultAddress).deposit(amount);

// withdraw from vault
TokenVault(vaultAddress).withdraw(amount);
```

---

## Running Tests

```bash
# add to .env
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY

# run tests against mainnet fork
forge test -vvvv
```

---

## Stack

- Solidity `^0.8.28`
- Foundry (Forge + Anvil)
- OpenZeppelin Contracts
- Mainnet Forking