// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract PixelPioneers is ERC721, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    //=====================================================
    //      ERRORS
    //=====================================================
    error PixelPioneers__MaxSupplyReached();
    error PixelPioneers__InsufficientPayment();
    error PixelPioneers__PresaleNotActive();
    error PixelPioneers__PublicSaleNotActive();
    error PixelPioneers__InvalidMerkleProof();
    error PixelPioneers__AlreadyMintedPresale();
    error PixelPioneers__WithdrawFailed();
    error PixelPioneers__TokenDoesNotExist();

    //=====================================================
    //      STATE VARIABLES
    //=====================================================
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public immutable i_mintPrice;

    uint256 private s_tokenCounter;
    string private s_baseTokenURI;
    string private s_notRevealedURI;
    bool public s_revealed;

    // Whitelist & Sale Controls
    bytes32 private s_merkleRoot;
    bool public s_presaleActive;
    bool public s_publicSaleActive;

    // Track if address already claimed presale mint
    mapping(address => bool) private s_hasMintedPresale;

    //=====================================================
    //      EVENTS
    //=====================================================
    event NFTMinted(address indexed minter, uint256 indexed tokenId);
    event SaleStateUpdated(bool presaleActive, bool publicSaleActive);
    event MerkleRootUpdated(bytes32 newMerkleRoot);
    event RevealStateUpdated(bool isRevealed);

    //=====================================================
    //      CONSTRUCTOR
    //=====================================================
    constructor(
        string memory baseURI,
        string memory notRevealedURI,
        uint256 mintPrice,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator // 500 = 5%
    ) ERC721("Pixel Pioneers", "PXP") Ownable(msg.sender) {
        s_baseTokenURI = baseURI;
        s_notRevealedURI = notRevealedURI;
        i_mintPrice = mintPrice;
        s_tokenCounter = 0;
        s_revealed = false;

        // Set default royalty (e.g. 5% to the creator)
        _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
    }

    //=====================================================
    //      MINT FUNCTION
    //=====================================================
    ////@notice Whitelist Presale Mint (requires valid Merkle Proof)
    function whitelistMint(
        bytes32[] calldata proof
    ) external payable nonReentrant {
        // 1. CHECKS
        if (!s_presaleActive) {
            revert PixelPioneers__PresaleNotActive();
        }
        if (s_hasMintedPresale[msg.sender]) {
            revert PixelPioneers__AlreadyMintedPresale();
        }

        // 1.1. Check supply
        if (s_tokenCounter >= MAX_SUPPLY) {
            revert PixelPioneers__MaxSupplyReached();
        }
        // 1.2. Check payment
        if (msg.value < i_mintPrice) {
            revert PixelPioneers__InsufficientPayment();
        }

        // Verify the Merkle proof for msg.sender
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender)))
        );
        if (!MerkleProof.verify(proof, s_merkleRoot, leaf)) {
            revert PixelPioneers__InvalidMerkleProof();
        }

        // 2. EFFECTS (Update state BEFORE external calls)
        s_hasMintedPresale[msg.sender] = true;
        uint256 newTokenId = s_tokenCounter;
        s_tokenCounter++;

        // 3. INTERACTIONS
        _safeMint(msg.sender, newTokenId);
        emit NFTMinted(msg.sender, newTokenId);
    }

    ////@notice Public Mint
    function publicMint() external payable nonReentrant {
        // 1. CHECKS
        if (!s_publicSaleActive) {
            revert PixelPioneers__PublicSaleNotActive();
        }
        if (s_tokenCounter >= MAX_SUPPLY) {
            revert PixelPioneers__MaxSupplyReached();
        }
        if (msg.value < i_mintPrice) {
            revert PixelPioneers__InsufficientPayment();
        }

        // 2. EFFECTS
        uint256 newTokenId = s_tokenCounter;
        s_tokenCounter++;

        // 3. INTERACTIONS
        _safeMint(msg.sender, newTokenId);
        emit NFTMinted(msg.sender, newTokenId);
    }

    //=====================================================
    //      OWNER FUNCTIONS
    //=====================================================

    function setRevealed(bool revealed) external onlyOwner {
        s_revealed = revealed;
        emit RevealStateUpdated(revealed);
    }

    function setNotRevealedURI(
        string memory notRevealedURI
    ) external onlyOwner {
        s_notRevealedURI = notRevealedURI;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        s_merkleRoot = newMerkleRoot;
        emit MerkleRootUpdated(newMerkleRoot);
    }

    function setSaleStates(
        bool presaleActive,
        bool publicSaleActive
    ) external onlyOwner {
        s_presaleActive = presaleActive;
        s_publicSaleActive = publicSaleActive;
        emit SaleStateUpdated(presaleActive, publicSaleActive);
    }

    ////@notice Allows the contract owner to witdraw accumulated ETH
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: balance}("");
        if (!success) {
            revert PixelPioneers__WithdrawFailed();
        }
    }

    ////@notice Allows the owner to update the base URI needed
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        s_baseTokenURI = newBaseURI;
    }

    //=====================================================
    //      VIEW FUNCTIONS
    //=====================================================
    /// @notice Returns the metadata URI for a given token ID
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert PixelPioneers__TokenDoesNotExist();
        }

        // If not revealed yet, return the hidden placeholder URI
        if (!s_revealed) {
            return s_notRevealedURI;
        }

        // Once revealed, return baseURI + tokenId + ".json"
        return string.concat(s_baseTokenURI, tokenId.toString(), ".json");
    }

    function getTokenCounter() external view returns (uint256) {
        return s_tokenCounter;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return s_merkleRoot;
    }

    function hasMintedPresale(address minter) external view returns (bool) {
        return s_hasMintedPresale[minter];
    }

    // =============================================================
    //                      INTERFACE OVERRIDE
    // =============================================================
    /// @dev Required override because both ERC721 and ERC2981 implement IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
