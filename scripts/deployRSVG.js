
const hre = require("hardhat");

async function main() {
  // rinkeby Chainlink Addresses and constructor parameters
  let vrfcoordinator = "0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B";
  let linktoken = "0x01BE23585060835E02B77ef475b0Cc51aA1e0709";
  let keyhash = "0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311";
  let fee = "100000000000000000";
  let args = [vrfcoordinator,linktoken,keyhash,fee];

  const NFT = await hre.ethers.getContractFactory("RandomSVG");
  const nFT = await NFT.deploy(vrfcoordinator,linktoken,keyhash,fee);
  await nFT.deployed();
  console.log("RandomSVG deployed to:", nFT.address);

  // wait before verifying on etherscan
  await new Promise(resolve => setTimeout(resolve, 35000));
  await hre.run("verify:verify", {
    address: nFT.address,
    constructorArguments: args,
    });
  console.log("verified");

  // fund smart contract with link token
  const linkTokenContract = await hre.ethers.getContractFactory("LinkToken");
  const accounts = await hre.ethers.getSigners();
  const signer = accounts[0];
  const linkToken = new hre.ethers.Contract(linktoken, linkTokenContract.interface, signer);
  let fund_tx = await linkToken.transfer(nFT.address, "1000000000000000000", {gasLimit: 300000});
  await fund_tx.wait(1);

  // create the first NFT
  let transactionResponse = await nFT.create();
  let receiptCreation = await transactionResponse.wait(1);
  console.log("created NFT");
  let tokenId = receiptCreation.events[3].topics[2];
  console.log("with the ID: ", tokenId.toString());
  
  // wait for chainlink node to return random value, ca. 3 mins on rinkeby
  await new Promise(r => setTimeout(r, 190000));
  let tokenuri = await nFT.tokenURI(0);
  console.log("view it here \n", tokenuri);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
