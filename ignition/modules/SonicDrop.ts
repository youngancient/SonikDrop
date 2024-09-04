import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const SonicDropModule = buildModule("SonicDropModule", (m) => {
 
  const sonicDrop = m.contract("SonicDrop");

  return { sonicDrop };
});

export default SonicDropModule;
