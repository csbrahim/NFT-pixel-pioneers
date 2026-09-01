// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PixelPioneers} from "../../src/PixelPioneers.sol";
import {DeployPixelPioneers} from "../../script/DeployPixelPioneers.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC2981} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

/// @dev Contract that rejects all ETH — used to force withdraw() to fail
contract RejectETH {
    // no receive() or fallback()
}

contract PixelPioneersTest is Test {
    PixelPioneers public nft;
    HelperConfig public helperConfig;

    // Config values retrieved from HelperConfig
    string public baseURI;
    string public notRevealedURI;
    uint256 public mintPrice;
    address public royaltyReceiver;
    uint96 public royaltyFeeBps;
    address public owner;

    // Test users
    address public wlUser1 = makeAddr("wlUser1");
    address public wlUser2 = makeAddr("wlUser2");
    address public wlUser3 = makeAddr("wlUser3");
    address public wlUser4 = makeAddr("wlUser4");
    address public regularUser = makeAddr("regularUser");

    // Constants
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    // Merkle Tree data
    bytes32 public merkleRoot;
    bytes32[] public proofUser1;

    //=====================================================
    //      SETUP
    //=====================================================
    function setUp() public {
        // Deploy using our production deployment script
        DeployPixelPioneers deployer = new DeployPixelPioneers();
        (nft, helperConfig) = deployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        baseURI = config.baseURI;
        notRevealedURI = config.notRevealedURI;
        mintPrice = config.mintPrice;
        royaltyReceiver = config.royaltyReceiver;
        royaltyFeeBps = config.royaltyFeeBps;
        owner = nft.owner();

        // Fund users
        vm.deal(wlUser1, STARTING_USER_BALANCE);
        vm.deal(wlUser2, STARTING_USER_BALANCE);
        vm.deal(regularUser, STARTING_USER_BALANCE);

        // 3. Build a 4-leaf Merkle Tree in Solidity:
        // leaf = keccak256(bytes.concat(keccak256(abi.encode(address))));
        bytes32 leaf1 = _getLeaf(wlUser1);
        bytes32 leaf2 = _getLeaf(wlUser2);
        bytes32 leaf3 = _getLeaf(wlUser3);
        bytes32 leaf4 = _getLeaf(wlUser4);

        // Branch 1 & 2
        bytes32 branch1 = _hashPair(leaf1, leaf2);
        bytes32 branch2 = _hashPair(leaf3, leaf4);

        // Merkle Root
        merkleRoot = _hashPair(branch1, branch2);

        // Proof for wlUser1 consists of: [leaf2, branch2]
        proofUser1.push(leaf2);
        proofUser1.push(branch2);

        // 4. Set Merkle Root on contract
        vm.prank(owner);
        nft.setMerkleRoot(merkleRoot);
    }

    //=====================================================
    //      HELPER FUNCTIONS TO BUILD MERKLE TREE
    //=====================================================
    function _getLeaf(address account) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(account))));
    }

    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return
            a < b
                ? keccak256(abi.encodePacked(a, b))
                : keccak256(abi.encodePacked(b, a));
    }

    // =============================================================
    //                       PRESALE TESTS
    // =============================================================

    function test_PresaleMintRevertsIfInactive() public {
        vm.prank(wlUser1);
        vm.expectRevert(PixelPioneers.PixelPioneers__PresaleNotActive.selector);
        nft.whitelistMint{value: mintPrice}(proofUser1);
    }

    function test_PresaleMintRevertsForNonWhitelistedUser() public {
        vm.prank(owner);
        nft.setSaleStates(true, false);

        vm.prank(regularUser);
        vm.expectRevert(
            PixelPioneers.PixelPioneers__InvalidMerkleProof.selector
        );
        nft.whitelistMint{value: mintPrice}(proofUser1);
    }

    function test_PresaleMintSuccessForWhitelistedUser() public {
        vm.prank(owner);
        nft.setSaleStates(true, false);

        vm.prank(wlUser1);
        nft.whitelistMint{value: mintPrice}(proofUser1);

        assertEq(nft.balanceOf(wlUser1), 1);
        assertEq(nft.ownerOf(0), wlUser1);
        assertTrue(nft.hasMintedPresale(wlUser1));
    }

    function test_PresaleMintRevertsIfAlreadyMinted() public {
        vm.prank(owner);
        nft.setSaleStates(true, false);

        vm.prank(wlUser1);
        nft.whitelistMint{value: mintPrice}(proofUser1);

        vm.prank(wlUser1);
        vm.expectRevert(
            PixelPioneers.PixelPioneers__AlreadyMintedPresale.selector
        );
        nft.whitelistMint{value: mintPrice}(proofUser1);
    }

    // =============================================================
    //                      PUBLIC SALE TESTS
    // =============================================================

    function test_PublicMintRevertsIfInactive() public {
        vm.prank(regularUser);
        vm.expectRevert(
            PixelPioneers.PixelPioneers__PublicSaleNotActive.selector
        );
        nft.publicMint{value: mintPrice}();
    }

    function test_PublicMintSuccessWhenActive() public {
        vm.prank(owner);
        nft.setSaleStates(false, true);

        vm.prank(regularUser);
        nft.publicMint{value: mintPrice}();

        assertEq(nft.balanceOf(regularUser), 1);
        assertEq(nft.ownerOf(0), regularUser);
    }

    function test_PublicMintRevertsIfInsufficientPayment() public {
        vm.prank(owner);
        nft.setSaleStates(false, true);

        vm.prank(regularUser);
        vm.expectRevert(
            PixelPioneers.PixelPioneers__InsufficientPayment.selector
        );
        nft.publicMint{value: 0.01 ether}();
    }

    // =============================================================
    //                       WITHDRAW TESTS
    // =============================================================

    function test_OwnerCanWithdrawFunds() public {
        vm.prank(owner);
        nft.setSaleStates(false, true);

        vm.prank(regularUser);
        nft.publicMint{value: mintPrice}();

        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(owner);
        nft.withdraw();

        assertEq(address(nft).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + mintPrice);
    }

    // =============================================================
    //                     REVEAL & URI TESTS
    // =============================================================

    function test_TokenURIBeforeRevealReturnsNotRevealedURI() public {
        vm.prank(owner);
        nft.setSaleStates(false, true);

        vm.prank(regularUser);
        nft.publicMint{value: mintPrice}();

        assertEq(nft.tokenURI(0), notRevealedURI);
    }

    function test_TokenURIAfterRevealReturnsCorrectURI() public {
        vm.prank(owner);
        nft.setSaleStates(false, true);

        vm.prank(regularUser);
        nft.publicMint{value: mintPrice}();

        vm.prank(owner);
        nft.setRevealed(true);

        string memory expectedURI = string.concat(baseURI, "0.json");
        assertEq(nft.tokenURI(0), expectedURI);
    }

    function test_TokenURIRevertsForNonExistentToken() public {
        vm.expectRevert(
            PixelPioneers.PixelPioneers__TokenDoesNotExist.selector
        );
        nft.tokenURI(999);
    }

    // =============================================================
    //                       ROYALTY TESTS
    // =============================================================

    function test_RoyaltyInfoIsCorrect() public view {
        uint256 salePrice = 1 ether;
        uint256 expectedRoyalty = (salePrice * royaltyFeeBps) / 10000;

        (address receiver, uint256 royaltyAmount) = nft.royaltyInfo(
            0,
            salePrice
        );

        assertEq(receiver, royaltyReceiver);
        assertEq(royaltyAmount, expectedRoyalty);
    }

    function test_SupportsExpectedInterfaces() public view {
        assertTrue(nft.supportsInterface(type(IERC721).interfaceId));
        assertTrue(nft.supportsInterface(type(IERC2981).interfaceId));
    }

    // =============================================================
    //                   OWNER / ACCESS CONTROL TESTS
    // =============================================================

    function test_NonOwnerCannotSetSaleStates() public {
        vm.prank(regularUser);
        vm.expectRevert();
        nft.setSaleStates(true, true);
    }

    function test_NonOwnerCannotSetMerkleRoot() public {
        vm.prank(regularUser);
        vm.expectRevert();
        nft.setMerkleRoot(bytes32(0));
    }

    function test_NonOwnerCannotSetRevealed() public {
        vm.prank(regularUser);
        vm.expectRevert();
        nft.setRevealed(true);
    }

    function test_NonOwnerCannotSetBaseURI() public {
        vm.prank(regularUser);
        vm.expectRevert();
        nft.setBaseURI("ipfs://hacked/");
    }

    function test_NonOwnerCannotSetNotRevealedURI() public {
        vm.prank(regularUser);
        vm.expectRevert();
        nft.setNotRevealedURI("ipfs://hacked/");
    }

    function test_NonOwnerCannotSetDefaultRoyalty() public {
        vm.prank(regularUser);
        vm.expectRevert();
        nft.setDefaultRoyalty(regularUser, 1000);
    }

    function test_NonOwnerCannotWithdraw() public {
        vm.prank(owner);
        nft.setSaleStates(false, true);

        vm.prank(regularUser);
        nft.publicMint{value: mintPrice}();

        vm.prank(regularUser);
        vm.expectRevert();
        nft.withdraw();
    }

    // =============================================================
    //                    OWNER SETTER SUCCESS TESTS
    // =============================================================

    function test_OwnerCanSetBaseURI() public {
        string memory newURI = "ipfs://QmNewHash/";
        vm.prank(owner);
        nft.setBaseURI(newURI);

        // Mint + reveal so tokenURI uses baseURI
        vm.prank(owner);
        nft.setSaleStates(false, true);
        vm.prank(regularUser);
        nft.publicMint{value: mintPrice}();
        vm.prank(owner);
        nft.setRevealed(true);

        assertEq(nft.tokenURI(0), string.concat(newURI, "0.json"));
    }

    function test_OwnerCanSetNotRevealedURI() public {
        string memory newHiddenURI = "ipfs://QmNewHidden/hidden.json";
        vm.prank(owner);
        nft.setNotRevealedURI(newHiddenURI);

        vm.prank(owner);
        nft.setSaleStates(false, true);
        vm.prank(regularUser);
        nft.publicMint{value: mintPrice}();

        assertEq(nft.tokenURI(0), newHiddenURI);
    }

    function test_OwnerCanSetDefaultRoyalty() public {
        address newReceiver = makeAddr("newRoyaltyReceiver");
        uint96 newFee = 250; // 2.5%

        vm.prank(owner);
        nft.setDefaultRoyalty(newReceiver, newFee);

        uint256 salePrice = 1 ether;
        (address receiver, uint256 amount) = nft.royaltyInfo(0, salePrice);

        assertEq(receiver, newReceiver);
        assertEq(amount, (salePrice * newFee) / 10000);
    }

    function test_OwnerCanSetMerkleRoot() public {
        bytes32 newRoot = keccak256("new root");
        vm.prank(owner);
        nft.setMerkleRoot(newRoot);
        assertEq(nft.getMerkleRoot(), newRoot);
    }

    // =============================================================
    //                      MAX SUPPLY TEST
    // =============================================================

    // Add this inside the contract
    using stdStorage for StdStorage;

    function test_MintRevertsWhenMaxSupplyReached() public {
        vm.prank(owner);
        nft.setSaleStates(false, true);

        // Use stdStorage to set s_tokenCounter = MAX_SUPPLY
        stdstore.target(address(nft)).sig("getTokenCounter()").checked_write(
            nft.MAX_SUPPLY()
        );

        vm.prank(regularUser);
        vm.expectRevert(PixelPioneers.PixelPioneers__MaxSupplyReached.selector);
        nft.publicMint{value: mintPrice}();
    }

    function test_WhitelistMintRevertsWhenMaxSupplyReached() public {
        vm.prank(owner);
        nft.setSaleStates(true, false);

        stdstore.target(address(nft)).sig("getTokenCounter()").checked_write(
            nft.MAX_SUPPLY()
        );

        vm.prank(wlUser1);
        vm.expectRevert(PixelPioneers.PixelPioneers__MaxSupplyReached.selector);
        nft.whitelistMint{value: mintPrice}(proofUser1);
    }

    // =============================================================
    //                    VIEW FUNCTION TESTS
    // =============================================================

    function test_GetTokenCounterStartsAtZero() public view {
        assertEq(nft.getTokenCounter(), 0);
    }

    function test_GetTokenCounterIncrementsAfterMint() public {
        vm.prank(owner);
        nft.setSaleStates(false, true);

        vm.prank(regularUser);
        nft.publicMint{value: mintPrice}();

        assertEq(nft.getTokenCounter(), 1);
    }

    function test_HasMintedPresaleDefaultsToFalse() public view {
        assertFalse(nft.hasMintedPresale(regularUser));
    }

    // =============================================================
    //                    TESTS
    // =============================================================

    function test_WithdrawRevertsIfTransferFails() public {
        // 1. Put ETH in the contract
        vm.prank(owner);
        nft.setSaleStates(false, true);

        vm.prank(regularUser);
        nft.publicMint{value: mintPrice}();

        // 2. Transfer ownership to a contract that cannot receive ETH
        RejectETH rejector = new RejectETH();
        vm.prank(owner);
        nft.transferOwnership(address(rejector));

        // 3. Owner (rejector) withdraws → ETH send fails → custom error
        vm.prank(address(rejector));
        vm.expectRevert(PixelPioneers.PixelPioneers__WithdrawFailed.selector);
        nft.withdraw();
    }

    function test_WhitelistMintRevertsIfInsufficientPayment() public {
        vm.prank(owner);
        nft.setSaleStates(true, false);

        vm.prank(wlUser1);
        vm.expectRevert(
            PixelPioneers.PixelPioneers__InsufficientPayment.selector
        );
        nft.whitelistMint{value: 0.01 ether}(proofUser1);
    }
}
