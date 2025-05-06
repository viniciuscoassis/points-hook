# PointsHook – Uniswap V4 AfterSwap Points Hook

## Overview

**PointsHook** is a custom [Uniswap V4](https://uniswap.org/blog/uniswap-v4) hook contract that rewards users with ERC1155 "points" tokens whenever they swap ETH for a specific ERC20 token in a Uniswap V4 pool. The points are minted at a rate of 20% of the ETH spent in the swap.

This project demonstrates how to use Uniswap V4's `afterSwap` hook to build on-chain loyalty or rewards systems.

## Features

- **ERC1155 Points:** Users receive ERC1155 tokens as "points" for eligible swaps.
- **ETH-to-Token Only:** Points are only minted when swapping ETH (currency0) for the paired ERC20 token (currency1).
- **20% Reward Rate:** For every swap, users receive points equal to 20% of the ETH they spend.
- **Pool-specific Points:** Points are tracked per pool, using the pool's unique ID as the ERC1155 token ID.

## How It Works

1. **Pool Setup:** Deploy a Uniswap V4 pool with ETH as `currency0` and your ERC20 as `currency1`, and register the `PointsHook` as the pool's hook.
2. **Swapping:** When a user swaps ETH for the ERC20 token, the `afterSwap` hook is triggered.
3. **Points Minting:** The hook checks the swap direction and mints ERC1155 points to the user, proportional to the ETH spent.

## Example

Suppose a user swaps 0.5 ETH for tokens. The hook mints `0.1` points (i.e., 0.5 / 5 = 0.1) to the user as ERC1155 tokens, with the pool's ID as the token ID.

## Usage

### Deployment

1. Deploy the `PointsHook` contract, passing the Uniswap V4 PoolManager address to the constructor.
2. Initialize a Uniswap V4 pool with ETH and your ERC20 token, registering the `PointsHook` as the hook.

### Testing

The project includes a Foundry test (`test/PointsHook.t.sol`) that demonstrates:

- Pool setup and liquidity provision
- Swapping ETH for the ERC20 token
- Asserting that points are correctly minted

Run tests with:

```sh
forge test
```

## Contract Details

- **Hook:** Implements only the `afterSwap` hook.
- **Points Minting:** Uses ERC1155 standard; points are non-transferable by default (can be customized).
- **URI:** Returns a static metadata URI for all points tokens.

## File Structure

- `src/PointsHook.sol` – The main hook contract.
- `test/PointsHook.t.sol` – Foundry test for the hook.
- `lib/` – Uniswap V4 and Solmate dependencies.

## License

MIT

---

**Note:** This project is for demonstration and research purposes. Use with caution in production environments.