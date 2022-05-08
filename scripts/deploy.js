const hre = require("hardhat");

async function main() {
  const CoolPenguinKuki = await hre.ethers.getContractFactory("CoolPenguinKuki");
  const coolPenguinKuki = await CoolPenguinKuki.deploy("https://gateway.pinata.cloud/ipfs/QmZHJGbeFp8gaMzxuUE7zdrUTuRzWhhYqR9QtiKg2Miihw/","0xF60d35351F0b0fCec3121A31B0022f20458484A3");
  await coolPenguinKuki.deployed();
  console.log("CoolPenguinKuki deployed to:", coolPenguinKuki.address);
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
