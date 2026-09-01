// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PixelPioneers} from "../src/PixelPioneers.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

/// @notice Enables public sale on the most recently deployed contract
contract EnablePublicSale is Script {
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "PixelPioneers",
            block.chainid
        );
        enablePublicSale(mostRecentlyDeployed);
    }

    function enablePublicSale(address contractAddress) public {
        vm.startBroadcast();
        PixelPioneers(contractAddress).setSaleStates(false, true);
        vm.stopBroadcast();
        console.log("Public sale enabled on:", contractAddress);
    }
}

/// @notice Mints one NFT via public sale on the most recently deployed contract
contract MintNFT is Script {
    uint256 public constant MINT_PRICE = 0.05 ether;

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "PixelPioneers",
            block.chainid
        );
        mintNFT(mostRecentlyDeployed);
    }

    function mintNFT(address contractAddress) public {
        vm.startBroadcast();
        PixelPioneers(contractAddress).publicMint{value: MINT_PRICE}();
        vm.stopBroadcast();
        console.log("NFT minted from:", contractAddress);
    }
}

/// @notice Reveals the collection on the most recently deployed contract
contract RevealCollection is Script {
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "PixelPioneers",
            block.chainid
        );
        revealCollection(mostRecentlyDeployed);
    }

    function revealCollection(address contractAddress) public {
        vm.startBroadcast();
        PixelPioneers(contractAddress).setRevealed(true);
        vm.stopBroadcast();
        console.log("Collection revealed on:", contractAddress);
    }
}
