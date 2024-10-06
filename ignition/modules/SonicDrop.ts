import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const SonikDropModule = buildModule("SonikDropModule", (m) => {
 
  const sonicDrop = m.contract("SonikDrop");

  return { sonicDrop };
});

export default SonikDropModule;
