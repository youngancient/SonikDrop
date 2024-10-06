import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const SonikDropFactoryModule = buildModule("SonikDropFactoryModule", (m) => {
 
  const sonikDropFactory = m.contract("SonikDropFactory");

  return { sonikDropFactory };
});

export default SonikDropFactoryModule;
