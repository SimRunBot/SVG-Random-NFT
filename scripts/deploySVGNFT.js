
const hre = require("hardhat");
const fs = require("fs");

async function main() {
  const NFT = await hre.ethers.getContractFactory("SVGNFT");
  const nFT = await NFT.deploy();

  await nFT.deployed();

  console.log("SVGNFT deployed to:", nFT.address);

  let filepath = "./images/circle.svg";
  let svg = fs.readFileSync(filepath, {encoding:"utf8"});

  await new Promise(resolve => setTimeout(resolve, 19000));
  /* await hre.run("verify:verify", {
    address: nFT.address,
    constructorArguments: [
      50,
      "a string argument",
      {
        x: 10,
        y: 5,
      },
      "0xabcdef",
    ],
  }); */

  await hre.run("verify:verify", {
    address: nFT.address
    });

  console.log("verified");
  
  let transactionResponse = await nFT.create(svg);
  let receipt = await transactionResponse.wait(1);
  console.log("created NFT");
  let tokenuri = await nFT.tokenURI(0);
  console.log("view it here \n", tokenuri);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
