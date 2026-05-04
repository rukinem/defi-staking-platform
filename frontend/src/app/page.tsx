"use client";
import { useState, useEffect } from "react";
import { ethers } from "ethers";

export default function Home() {
  const [account, setAccount] = useState<string | null>(null);
  const [balance, setBalance] = useState<string>("0");

  const connectWallet = async () => {
    if (typeof window.ethereum !== "undefined") {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const accounts = await provider.send("eth_requestAccounts", []);
      setAccount(accounts[0]);
      const bal = await provider.getBalance(accounts[0]);
      setBalance(ethers.formatEther(bal));
    } else {
      alert("Please install MetaMask!");
    }
  };

  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8">
      <h1 className="text-4xl font-bold mb-8">dApp</h1>
      {account ? (
        <div className="text-center space-y-4">
          <p className="text-sm text-gray-500">Connected: {account.slice(0,6)}...{account.slice(-4)}</p>
          <p className="text-lg font-semibold">Balance: {parseFloat(balance).toFixed(4)} ETH</p>
        </div>
      ) : (
        <button onClick={connectWallet} className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition">Connect Wallet</button>
      )}
    </main>
  );
}
