// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console2, console} from "forge-std/Test.sol";
import {Deployers} from "v4-periphery/lib/v4-core/test/utils/Deployers.sol";
import {ERC1155TokenReceiver} from "solmate/src/tokens/ERC1155.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {IHooks} from "v4-periphery/lib/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {SwapParams} from "v4-core/interfaces/IPoolManager.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";

import {PointsHook} from "../src/PointsHook.sol";

contract PointsHookTest is Test, Deployers, ERC1155TokenReceiver {
    MockERC20 token;
    Currency ethCurrency = Currency.wrap(address(0));
    Currency tokenCurrency;

    PointsHook hook;

    function setUp() public {
        deployFreshManagerAndRouters();

        token = new MockERC20("TEST", "TEST", 18);
        tokenCurrency = Currency.wrap(address(token));

        token.mint(address(this), 10000e18);

        token.approve(address(swapRouter), type(uint256).max);
        token.approve(address(modifyLiquidityRouter), type(uint256).max);

        // uint160 flags = (uint160(0x4444 << 144 | 1 << 3));
        uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG);

        deployCodeTo("PointsHook.sol", abi.encode(manager), address(flags));

        hook = PointsHook(address(flags));

        // Initialize a pool
        (key,) = initPool(
            ethCurrency, // Currency 0 = ETH
            tokenCurrency, // Currency 1 = TOKEN
            hook, // Hook Contract
            3000, // Swap Fees
            SQRT_PRICE_1_1 // Initial Sqrt(P) value = 1
        );

        // Add liquidity
        uint160 sqrtTickLower = TickMath.getSqrtPriceAtTick(-60);
        uint160 sqrtTickUpper = TickMath.getSqrtPriceAtTick(60);

        vm.deal(address(this), 10 ether);
        uint256 ethToAdd = 1 ether;

        console2.log("this eth balance BEFORE: %e", address(this).balance);
        console2.log("this token balance BEFORE: %e", token.balanceOf(address(this)));
        uint128 liquidityDelta = LiquidityAmounts.getLiquidityForAmount0(sqrtTickLower, SQRT_PRICE_1_1, ethToAdd);
        uint256 tokenToAdd = LiquidityAmounts.getAmount1ForLiquidity(sqrtTickUpper, SQRT_PRICE_1_1, liquidityDelta);

        modifyLiquidityRouter.modifyLiquidity{value: ethToAdd}(
            key,
            ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: int256(uint256(liquidityDelta)),
                salt: bytes32(0)
            }),
            ZERO_BYTES
        );

        console2.log("this eth balance AFTER: %e", address(this).balance);
        console2.log("this token balance AFTER: %e", token.balanceOf(address(this)));
    }

    function test_points_hook() public {
        uint256 poolIdUint = uint256(PoolId.unwrap(key.toId()));
        uint256 pointsBalanceOriginal = hook.balanceOf(address(this), poolIdUint);
        bytes memory hookData = abi.encode(address(this));

        swapRouter.swap{value: 0.5 ether}(
            key,
            SwapParams({zeroForOne: true, amountSpecified: -0.5 ether, sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1}),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            hookData
        );

        uint256 pointsBalanceAfterSwap = hook.balanceOf(address(this), poolIdUint);
        assertEq(pointsBalanceAfterSwap - pointsBalanceOriginal, 1e17);
    }
}
