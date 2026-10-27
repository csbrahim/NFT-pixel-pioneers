export const PIXEL_PIONEERS_ADDRESS = "0xCBAd8e8b77992de82D7D69230f56Df8F6e174803" as const;

export const PIXEL_PIONEERS_ABI = [
  {
    type: "function",
    name: "publicMint",
    inputs: [],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "whitelistMint",
    inputs: [{ name: "proof", type: "bytes32[]" }],
    outputs: [],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "totalSupply",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "MAX_SUPPLY",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "i_mintPrice",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "royaltyInfo",
    inputs: [
      { name: "tokenId", type: "uint256" },
      { name: "salePrice", type: "uint256" }
    ],
    outputs: [
      { name: "receiver", type: "address" },
      { name: "royaltyAmount", type: "uint256" }
    ],
    stateMutability: "view",
  },
] as const;
