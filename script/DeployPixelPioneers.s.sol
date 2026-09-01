// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PixelPioneers} from "../src/PixelPioneers.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployPixelPioneers is Script {
    function run() external returns (PixelPioneers, HelperConfig) {
        // Any calculation outside broadcast is free (simulation only)
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();

        PixelPioneers nft = new PixelPioneers(
            config.baseURI,
            config.notRevealedURI,
            config.mintPrice,
            config.royaltyReceiver,
            config.royaltyFeeBps
        );

        vm.stopBroadcast();

        console.log("PixelPioneers deployed at:", address(nft));
        return (nft, helperConfig);
    }
}
