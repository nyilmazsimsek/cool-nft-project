const hre = require("hardhat");

async function main() {
  const CoolPenguinKuki = await hre.ethers.getContractFactory("CoolPenguinKuki");
  const coolPenguinKuki = await CoolPenguinKuki.deploy("","");
  await coolPenguinKuki.deployed();
  console.log("CoolPenguinKuki deployed to:", coolPenguinKuki.address);
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
