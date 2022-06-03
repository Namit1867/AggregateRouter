const hre = require("hardhat");
require("@nomiclabs/hardhat-etherscan");


async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    const tokens = ["BUSD","BTCB","USDC","USDT","DAI","EXO","CAKE"];
    const deployer = (await hre.ethers.getSigner()).address;

    for(var i = 0 ; i < tokens.length ; i++){
        const element = tokens[i];
        const name = element;
        const symbol = element;
        const bep20 = await hre.ethers.getContractFactory("contracts/Token.sol:Token");
        const bep20_instance = await bep20.deploy(name,symbol);


        console.log(`\n ${name} DEPLOYED ADDRESS`,bep20_instance.address,"\n");

        // await bep20_instance.mint(deployer,"100000000000000000000000000000000000000000000000000");
    }
  
    
  }
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  