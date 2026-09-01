# Pixel Pioneers

Production-style **ERC-721 NFT drop** contract built with **Solidity** and **Foundry**.

Includes whitelist presale (Merkle proofs), public sale, delayed reveal, ERC-2981 royalties, and a full unit + integration test suite with **100% line coverage** on the core contract.

**Live (Sepolia):** [`0xCBAd8e8b77992de82D7D69230f56Df8F6e174803`](https://sepolia.etherscan.io/address/0xCBAd8e8b77992de82D7D69230f56Df8F6e174803#code) · Verified on Etherscan

---

## Features

| Feature               | Implementation                                                    |
| --------------------- | ----------------------------------------------------------------- |
| **ERC-721**           | OpenZeppelin `ERC721` + `_safeMint`                               |
| **Presale whitelist** | Merkle proofs via `MerkleProof.verify` (no on-chain address list) |
| **Public sale**       | Payable `publicMint()` with supply + price checks                 |
| **Delayed reveal**    | Shared placeholder URI until `setRevealed(true)`                  |
| **Royalties**         | ERC-2981 default royalty (basis points)                           |
| **Access control**    | OpenZeppelin `Ownable`                                            |
| **Security**          | Custom errors, CEI pattern, `ReentrancyGuard`, pull withdrawals   |
| **Tooling**           | Foundry scripts, `HelperConfig`, Makefile, gas snapshots          |

---

## Architecture

```text
pixel-pioneers/
├── src/
│   └── PixelPioneers.sol
├── script/
│   ├── DeployPixelPioneers.s.sol
│   ├── HelperConfig.s.sol
│   └── Interactions.s.sol
└── test/
    ├── unit/
    └── integration/
```

```text
                 ┌─────────────────────────┐
                 │    PixelPioneers.sol    │
                 └───────────┬─────────────┘
           ┌─────────────────┼─────────────────┐
           ▼                 ▼                 ▼
     ERC-721 minting   ERC-2981 royalties   Ownable + ReentrancyGuard
     + tokenURI/reveal   (BPS receiver)     + Merkle whitelist
```

## Sale Lifecycle

| Phase        | Function                         | Who                                                           |
| ------------ | -------------------------------- | ------------------------------------------------------------- |
| **Presale**  | `whitelistMint(bytes32[] proof)` | Whitelisted addresses with valid Merkle proof                 |
| **Public**   | `publicMint()`                   | Anyone, while public sale is active                           |
| **Reveal**   | `setRevealed(true)`              | Owner only — switches metadata from placeholder to final URIs |
| **Withdraw** | `withdraw()`                     | Owner pulls ETH from sales                                    |

Default mint price: **0.05 ETH** · Max supply: **1000** · Default royalty: **5% (500 BPS)**

## Quickstart

### Requirements

1. Foundry
2. Git

### Setup

```bash
git clone <your-repo-url>
cd pixel-pioneers
make install
make build
```

### Environment

Create a `.env` file. Never commit this file.

```bash
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
PRIVATE_KEY=your_burner_testnet_private_key
ETHERSCAN_API_KEY=your_etherscan_api_key
```

Load the variables:

```bash
source .env
```

## Tests & Coverage

```bash
make test # full suite
make test-unit # test/unit only
make test-integration # test/integration only
make coverage # coverage report (src-focused)
make snapshot # gas snapshot
```

### Coverage (Core Contract)

| File                               | Lines    | Statements | Branches | Funcs    |
| ---------------------------------- | -------- | ---------- | -------- | -------- |
| `src/PixelPioneers.sol`            | **100%** | **100%**   | **100%** | **100%** |
| `script/HelperConfig.s.sol`        | 100%     | 100%       | 100%     | 100%     |
| `script/DeployPixelPioneers.s.sol` | 100%     | 100%       | —        | 100%     |

Note: Interactions.s.sol run() helpers rely on DevOpsTools against broadcast artifacts; core interaction logic is covered in integration tests.

## Deployment

### Local (Anvil)

```bash

    # Terminal 1

    make anvil

    # Terminal 2

    make deploy
```

### Sepolia (Deploy + Verify)

```bash

make deploy-sepolia
```

### Interactions via Makefile

```bash

make enable-sale ARGS="--network sepolia" # setSaleStates(false, true)
make mint ARGS="--network sepolia" # publicMint {value: 0.05 ether}
make reveal ARGS="--network sepolia" # setRevealed(true)
```

Or with cast:

```bash

cast send <CONTRACT> "setSaleStates(bool,bool)" false true --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
cast send <CONTRACT> "publicMint()" --value 0.05ether --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
cast call <CONTRACT> "tokenURI(uint256)" 0 --rpc-url $SEPOLIA_RPC_URL
```

## Security Best Practices

- **CEI Pattern:** All state changes occur before external calls and `_safeMint`.
- **Custom Errors:** Gas-efficient, typed error reverts.
- **ReentrancyGuard:** Implemented on payable mint and withdrawal logic.
- **Pull Payments:** Secure owner withdrawal using low-level `call{value: ...}("")` with explicit success checks.
- **Merkle Whitelist:** Off-chain verification saves on-chain storage costs.

This is an educational / portfolio contract. Audit before any mainnet use with real funds.

## License

MIT
