import { ethers } from "ethers";

export const CONTRACT_ABI: any[] = []; // TODO: Add ABI
export const CONTRACT_ADDRESS = "0x..."; // TODO: Add deployed address

export async function getContract() {
  if (typeof window.ethereum === "undefined") throw new Error("No wallet");
  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner();
  return new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
}
