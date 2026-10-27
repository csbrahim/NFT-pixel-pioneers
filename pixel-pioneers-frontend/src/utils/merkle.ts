import { MerkleTree } from 'merkletreejs';
import keccak256 from 'keccak256';

// List of whitelisted addresses (Include standard dev addresses + placeholder)
export const WHITELIST_ADDRESSES: string[] = [
  "0xadebd6615b31f13b2e5330386ff00868f722aec9", // User address
  "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
];

function hashAddress(address: string): Buffer {
  // Ensure lowercase address matching ERC-721 Merkle standards
  return keccak256(address.toLowerCase());
}

export function getMerkleTree(): MerkleTree {
  const leaves = WHITELIST_ADDRESSES.map((addr) => hashAddress(addressToLeaf(addr)));
  return new MerkleTree(leaves, keccak256, { sortPairs: true });
}

function addressToLeaf(address: string): string {
  return address.toLowerCase();
}

export function getMerkleProof(userAddress: string): `0x${string}`[] {
  if (!userAddress) return [];
  
  const leaves = WHITELIST_ADDRESSES.map((addr) => keccak256(addr.toLowerCase()));
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
  
  const userLeaf = keccak256(userAddress.toLowerCase());
  const proof = tree.getHexProof(userLeaf);
  
  return proof as `0x${string}`[];
}

export function isAddressWhitelisted(userAddress: string): boolean {
  if (!userAddress) return false;
  return WHITELIST_ADDRESSES.some(
    (addr) => addr.toLowerCase() === userAddress.toLowerCase()
  );
}