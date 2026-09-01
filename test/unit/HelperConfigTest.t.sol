// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    function test_AnvilConfigIsSetByDefault() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        assertEq(config.mintPrice, 0.05 ether);
        assertEq(config.royaltyFeeBps, 500);
        assertEq(config.royaltyReceiver, helperConfig.ANVIL_DEFAULT_ACCOUNT());
        assertEq(config.baseURI, "ipfs://QmRealHash/");
        assertEq(config.notRevealedURI, "ipfs://QmHiddenBox/hidden.json");
    }

    function test_SepoliaConfigWhenChainIdIsSepolia() public {
        // Simulate Sepolia chain ID
        vm.chainId(11155111);

        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        assertEq(config.mintPrice, 0.05 ether);
        assertEq(config.royaltyFeeBps, 500);
        assertEq(config.baseURI, "ipfs://QmRealHash/");
        // royaltyReceiver should be your sepolia deployer address from HelperConfig
        assertEq(
            config.royaltyReceiver,
            0xadeBd71604AC927D0ca67BDd99a3f9127192aeC9
        );
    }

    function test_MainnetConfigWhenChainIdIsMainnet() public {
        vm.chainId(1);

        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        assertEq(config.mintPrice, 0.05 ether);
        assertEq(config.royaltyFeeBps, 500);
        assertEq(config.royaltyReceiver, address(0)); // Placeholder until set
        assertEq(config.baseURI, "ipfs://REPLACE_WITH_REAL_MAINNET_HASH/");
    }

    function test_GetSepoliaConfigDirectly() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig
            .getSepoliaConfig();

        assertEq(config.royaltyFeeBps, 500);
        assertEq(config.mintPrice, 0.05 ether);
    }

    function test_GetMainnetConfigDirectly() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig
            .getMainnetConfig();

        assertEq(config.royaltyReceiver, address(0));
    }

    function test_GetAnvilConfigDirectly() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig
            .getOrCreateAnvilConfig();

        assertEq(config.royaltyReceiver, helperConfig.ANVIL_DEFAULT_ACCOUNT());
    }
}
