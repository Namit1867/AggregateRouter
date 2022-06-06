const { expect, assert } = require("chai");
const { waffle} = require("hardhat");
const provider = waffle.provider;
const { ethers, BigNumber } = require("ethers");
const { formatEther } = require("ethers/lib/utils");

const paths = [
    {
        "routerAddresses":["0x10ED43C718714eb63d5aA57B78B54704E256024E"],
        "path":[["0x2170Ed0880ac9A755fd29B2688956BD959F933F8","0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"]]
    },
    {
        "routerAddresses":["0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8"],
        "path":[["0x2170Ed0880ac9A755fd29B2688956BD959F933F8","0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"]]
    },
    {
        "routerAddresses":["0x10ED43C718714eb63d5aA57B78B54704E256024E","0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8"],
        "path":[["0x2170Ed0880ac9A755fd29B2688956BD959F933F8","0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c"],["0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c","0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"]]
    },
    {
        "routerAddresses":["0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8","0x10ED43C718714eb63d5aA57B78B54704E256024E"],
        "path":[["0x2170Ed0880ac9A755fd29B2688956BD959F933F8","0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c"],["0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c","0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"]]
    },
    {
        "routerAddresses":["0x10ED43C718714eb63d5aA57B78B54704E256024E","0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8"],
        "path":[["0x2170Ed0880ac9A755fd29B2688956BD959F933F8","0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"],["0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56","0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"]]
    },
    {
        "routerAddresses":["0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8","0x10ED43C718714eb63d5aA57B78B54704E256024E"],
        "path":[["0x2170Ed0880ac9A755fd29B2688956BD959F933F8","0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"],["0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56","0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"]]
    }
]

const pancakeFactory = "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73"
const biswapFactory  = "0x858E3312ed3A876947EA49d572A7C42DE08af7EE"
const pancakeRouter  = "0x10ED43C718714eb63d5aA57B78B54704E256024E"
const biswapRouter   = "0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8"


const tokens = [
    "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",  //BNB
    "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c",  //BTCB
    "0x2170Ed0880ac9A755fd29B2688956BD959F933F8",  //ETH
    "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56",  //BUSD
]

describe('Aggregator Contracts',() =>{
    
    it("print BNB different output",async() =>{

        pancakeFactoryInstance = await hre.ethers.getContractAt("ExoFactory",pancakeFactory);
        biswapFactoryInstance = await hre.ethers.getContractAt("ExoFactory",biswapFactory);
        pancakeRouterInstance = await hre.ethers.getContractAt("ExoRouter",pancakeRouter);
        biswapRouterInstance = await hre.ethers.getContractAt("ExoRouter",biswapRouter);

        for (let i = 0; i < paths.length; i++) {

            const routers = paths[i].routerAddresses;
            const routes = paths[i].path

            const amountIn = ethers.utils.parseEther("10");
            let amountOut = amountIn;

            for (let j = 0; j < routers.length; j++) {

                if(routers[j] === pancakeRouter){
                    amountOut = (await pancakeRouterInstance.getAmountsOut(amountOut,routes[j]))[routes[j].length-1];
                }
                else if(routers[j] === biswapRouter){
                    amountOut = (await biswapRouterInstance.getAmountsOut(amountOut,routes[j]))[routes[j].length-1];
                }
                
            }

            console.log(i,ethers.utils.formatEther(amountOut));
    
        }
        

    })

})