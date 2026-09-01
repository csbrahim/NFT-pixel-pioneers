// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PixelPioneers} from "../../src/PixelPioneers.sol";
import {DeployPixelPioneers} from "../../script/DeployPixelPioneers.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {EnablePublicSale, MintNFT, RevealCollection} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    PixelPioneers public nft;
    HelperConfig public helperConfig;

    // Foundry's default sender address during script broadcasts in tests
    //address public constant DEFAULT_SENDER =0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    function setUp() public {
        DeployPixelPioneers deployer = new DeployPixelPioneers();
        (nft, helperConfig) = deployer.run();
    }

    function test_FullUserJourney_MintThenReveal() public {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Step 1: Owner enables public sale via script (startBroadcast sets sender automatically)
        EnablePublicSale enableScript = new EnablePublicSale();
        enableScript.enablePublicSale(address(nft));
        assertTrue(nft.s_publicSaleActive());

        // Step 2: User mints an NFT via script
        MintNFT mintScript = new MintNFT();
        mintScript.mintNFT(address(nft));
        assertEq(nft.balanceOf(DEFAULT_SENDER), 1);
        assertEq(nft.ownerOf(0), DEFAULT_SENDER);

        // Step 3: Pre-reveal URI check
        assertEq(nft.tokenURI(0), config.notRevealedURI);

        // Step 4: Owner triggers reveal via script
        RevealCollection revealScript = new RevealCollection();
        revealScript.revealCollection(address(nft));
        assertTrue(nft.s_revealed());

        // Step 5: Post-reveal URI check
        string memory expectedURI = string.concat(config.baseURI, "0.json");
        assertEq(nft.tokenURI(0), expectedURI);
    }

    function test_MintNFTScriptExecutesSuccessfully() public {
        // Enable public sale
        EnablePublicSale enableScript = new EnablePublicSale();
        enableScript.enablePublicSale(address(nft));

        // Execute mint script
        MintNFT mintScript = new MintNFT();
        mintScript.mintNFT(address(nft));

        // DEFAULT_SENDER (who executed the broadcast) owns 1 NFT
        assertEq(nft.balanceOf(DEFAULT_SENDER), 1);
    }
}
