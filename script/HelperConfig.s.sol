// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    // =============================================================
    //                           STRUCTS
    // =============================================================
    struct NetworkConfig {
        string baseURI;
        string notRevealedURI;
        uint256 mintPrice;
        address royaltyReceiver;
        uint96 royaltyFeeBps;
    }

    // =============================================================
    //                      STATE VARIABLES
    // =============================================================
    NetworkConfig public activeNetworkConfig;

    // Anvil default first account (deterministic for local testing)
    address public constant ANVIL_DEFAULT_ACCOUNT =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // =============================================================
    //                        CONSTRUCTOR
    // =============================================================
    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    // =============================================================
    //                       NETWORK CONFIGS
    // =============================================================
    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                baseURI: "ipfs://QmRealHash/",
                notRevealedURI: "ipfs://QmHiddenBox/hidden.json",
                mintPrice: 0.05 ether,
                royaltyReceiver: 0xadeBd71604AC927D0ca67BDd99a3f9127192aeC9, // Your deployer wallet
                royaltyFeeBps: 500 // 5%
            });
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                baseURI: "ipfs://REPLACE_WITH_REAL_MAINNET_HASH/",
                notRevealedURI: "ipfs://REPLACE_WITH_HIDDEN_HASH/hidden.json",
                mintPrice: 0.05 ether,
                royaltyReceiver: address(0), // MUST be set before mainnet deployment
                royaltyFeeBps: 500
            });
    }

    function getOrCreateAnvilConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                baseURI: "ipfs://QmRealHash/",
                notRevealedURI: "ipfs://QmHiddenBox/hidden.json",
                mintPrice: 0.05 ether,
                royaltyReceiver: ANVIL_DEFAULT_ACCOUNT,
                royaltyFeeBps: 500
            });
    }

    function getConfig() external view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
