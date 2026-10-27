import type { Metadata } from 'next';
import './globals.css';
import { Web3Provider } from '@/components/Web3Provider';

export const metadata: Metadata = {
  title: 'Pixel Pioneers | Whitelist NFT Drop',
  description: 'ERC-721 Whitelist NFT Drop with Merkle proofs & royalties',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-black text-white antialiased">
        <Web3Provider>{children}</Web3Provider>
      </body>
    </html>
  );
}