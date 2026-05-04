import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { mainnet, arbitrum, base, polygon } from "wagmi/chains";

export const config = getDefaultConfig({
  appName: "dApp",
  projectId: "YOUR_PROJECT_ID",
  chains: [mainnet, arbitrum, base, polygon],
});
