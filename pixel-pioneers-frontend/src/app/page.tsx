"use client";

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { PIXEL_PIONEERS_ADDRESS, PIXEL_PIONEERS_ABI } from '@/config/contract';
import { getMerkleProof, isAddressWhitelisted } from '@/utils/merkle';
import { formatEther, parseEther } from 'viem';
import { ShieldCheck, ShieldAlert, Sparkles, Layers, Award } from 'lucide-react';

export default function Home() {
  const { isConnected, address } = useAccount();

  // 1. Read total supply
  const { data: rawTotalSupply, refetch: refetchTotalSupply } = useReadContract({
    address: PIXEL_PIONEERS_ADDRESS as `0x${string}`,
    abi: PIXEL_PIONEERS_ABI,
    functionName: 'totalSupply',
  });

  // 2. Read MAX_SUPPLY
  const { data: rawMaxSupply } = useReadContract({
    address: PIXEL_PIONEERS_ADDRESS as `0x${string}`,
    abi: PIXEL_PIONEERS_ABI,
    functionName: 'MAX_SUPPLY',
  });

  // 3. Read price from contract (i_mintPrice)
  const { data: rawPrice } = useReadContract({
    address: PIXEL_PIONEERS_ADDRESS as `0x${string}`,
    abi: PIXEL_PIONEERS_ABI,
    functionName: 'i_mintPrice',
  });

  // Mint Hooks
  const { writeContract, data: txHash, isPending: isSigning, error: writeError } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({ hash: txHash });

  const totalSupply = typeof rawTotalSupply === 'bigint' ? Number(rawTotalSupply) : 0;
  const maxSupply = typeof rawMaxSupply === 'bigint' ? Number(rawMaxSupply) : 10000;
  const progressPercent = Math.min((totalSupply / maxSupply) * 100, 100);
  
  // Dynamic Mint Price (Defaults to 0.01 ETH if loading)
  const mintPrice = typeof rawPrice === 'bigint' ? rawPrice : parseEther("0.01");

  const isWhitelisted = address ? isAddressWhitelisted(address) : false;
  const proof = address ? getMerkleProof(address) : [];

  const handleMintPublic = () => {
    writeContract({
      address: PIXEL_PIONEERS_ADDRESS as `0x${string}`,
      abi: PIXEL_PIONEERS_ABI,
      functionName: 'publicMint',
      value: mintPrice,
    }, {
      onSuccess: () => refetchTotalSupply()
    });
  };

  const handleMintWhitelist = () => {
    writeContract({
      address: PIXEL_PIONEERS_ADDRESS as `0x${string}`,
      abi: PIXEL_PIONEERS_ABI,
      functionName: 'whitelistMint',
      args: [proof],
      value: mintPrice,
    }, {
      onSuccess: () => refetchTotalSupply()
    });
  };

  return (
    <main className="min-h-screen bg-black text-white p-6 md:p-12">
      {/* Header */}
      <nav className="flex justify-between items-center mb-12 border-b border-gray-800 pb-6 max-w-5xl mx-auto">
        <div className="flex items-center gap-3">
          <Sparkles className="text-yellow-400" size={28} />
          <h1 className="text-2xl md:text-3xl font-black tracking-tight">PIXEL PIONEERS</h1>
        </div>
        <ConnectButton />
      </nav>

      <div className="max-w-5xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
        {/* NFT Preview Card */}
        <div className="bg-gray-900 border border-gray-800 p-8 rounded-3xl text-center shadow-2xl">
          <div className="aspect-square bg-gradient-to-br from-indigo-900 via-purple-900 to-pink-900 rounded-2xl mb-6 flex flex-col items-center justify-center border border-purple-500/30 p-6">
            <Layers size={64} className="text-purple-400 mb-4 animate-bounce" />
            <h3 className="text-xl font-bold">Unrevealed Pioneer</h3>
            <p className="text-xs text-gray-400 mt-2">Delayed reveal active on-chain</p>
          </div>

          {/* EIP-2981 Royalty Badge */}
          <div className="flex items-center justify-center gap-2 bg-gray-800/60 py-2.5 px-4 rounded-full text-xs text-gray-300 border border-gray-700">
            <Award size={14} className="text-yellow-400" />
            <span>EIP-2981 Royalties: 5% Creator Fee</span>
          </div>
        </div>

        {/* Mint Console */}
        <div className="space-y-6">
          <div>
            <h2 className="text-4xl font-extrabold mb-2">Claim Your Pioneer</h2>
            <p className="text-gray-400">Official ERC-721 Whitelist & Public Drop (1 per transaction)</p>
          </div>

          {/* Progress Bar */}
          <div className="bg-gray-900 border border-gray-800 p-4 rounded-2xl space-y-2">
            <div className="flex justify-between text-sm font-semibold">
              <span className="text-gray-400">Total Minted</span>
              <span className="text-purple-400">{totalSupply} / {maxSupply}</span>
            </div>
            <div className="w-full bg-gray-800 h-3 rounded-full overflow-hidden">
              <div 
                className="bg-gradient-to-r from-purple-500 to-pink-500 h-full transition-all duration-500"
                style={{ width: `${Math.max(progressPercent, 5)}%` }}
              />
            </div>
          </div>

          {/* Whitelist Status Box */}
          {isConnected && (
            <div className={`p-4 rounded-2xl border flex items-center gap-3 text-sm ${
              isWhitelisted 
                ? 'bg-green-950/40 border-green-500/40 text-green-300' 
                : 'bg-yellow-950/40 border-yellow-500/40 text-yellow-300'
            }`}>
              {isWhitelisted ? (
                <>
                  <ShieldCheck size={20} className="text-green-400 flex-shrink-0" />
                  <div>
                    <span className="font-bold">Whitelisted!</span> Merkle proof verified client-side.
                  </div>
                </>
              ) : (
                <>
                  <ShieldAlert size={20} className="text-yellow-400 flex-shrink-0" />
                  <div>
                    <span className="font-bold">Public Mode</span> Address not in presale Merkle root.
                  </div>
                </>
              )}
            </div>
          )}

          {/* Action Buttons */}
          {!isConnected ? (
            <div className="p-4 bg-gray-900 border border-gray-800 rounded-2xl text-center text-gray-400">
              Connect wallet to mint
            </div>
          ) : (
            <div className="space-y-3">
              {isWhitelisted && (
                <button
                  onClick={handleMintWhitelist}
                  disabled={isSigning || isConfirming}
                  className="w-full py-4 bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-400 hover:to-emerald-500 text-white font-black rounded-2xl transition-all active:scale-95 disabled:opacity-50"
                >
                  {isSigning ? "Signing Proof..." : isConfirming ? "Minting..." : `PRESALE MINT (${formatEther(mintPrice)} ETH)`}
                </button>
              )}

              <button
                onClick={handleMintPublic}
                disabled={isSigning || isConfirming}
                className="w-full py-4 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-500 hover:to-pink-500 text-white font-black rounded-2xl transition-all active:scale-95 disabled:opacity-50"
              >
                {isSigning ? "Signing..." : isConfirming ? "Minting..." : `PUBLIC MINT (${formatEther(mintPrice)} ETH)`}
              </button>
            </div>
          )}

          {writeError && (
            <div className="p-4 bg-red-900/40 border border-red-500/50 text-red-300 rounded-xl text-center text-xs">
              Error: {writeError.message.slice(0, 140)}
            </div>
          )}

          {isConfirmed && (
            <div className="p-4 bg-green-900/40 border border-green-500/50 text-green-300 rounded-xl text-center text-sm space-y-2">
              <div>
                🎉 Mint Successful!{' '}
                {txHash && (
                  <a
                    href={`https://sepolia.etherscan.io/tx/${txHash}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="underline font-bold hover:text-green-200"
                  >
                    View on Sepolia Etherscan.
                  </a>
                )}
              </div>
              <p className="text-xs text-green-400/80">
                Note: In MetaMask, newly minted NFTs may appear as blank/unrevealed until metadata is fully revealed on-chain by the creator.
              </p>
            </div>
          )}
        </div>
      </div>
    </main>
  );
}