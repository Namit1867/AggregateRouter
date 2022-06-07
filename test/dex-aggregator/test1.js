const tokens = (n) => {
    const x = ethers.utils.parseEther(n.toString());
    return x;
}

describe('Dex Aggragator',() =>{

    let dexAggregatorInstance;
    let dexAggregatorAddress;

    before (async() =>{
        [deployer,addr1,addr2,addr3,addr4,addr5,addr6] = await hre.ethers.getSigners();

        const dexAggregator = await hre.ethers.getContractFactory("DexAggregator");
        dexAggregatorInstance = await dexAggregator.deploy();
        dexAggregatorAddress = dexAggregatorInstance.address;

        BTCBInstance = await hre.ethers.getContractAt("Token","0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c"); //BTCB
        BTCBAddress = BTCBInstance.address;

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: ["0xF977814e90dA44bFA03b6295A0616a897441aceC"],
        });

        const impersonate0 = await hre.ethers.getSigner("0xF977814e90dA44bFA03b6295A0616a897441aceC");
        await BTCBInstance.connect(impersonate0).transfer(addr1.address,await BTCBInstance.balanceOf(impersonate0.address))
    })

    it ('checks swap function',async() =>{
        const desc = 
        [
         ["0x10ED43C718714eb63d5aA57B78B54704E256024E",
         ["0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c","0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"], //btcb to busd
         tokens(20000)
         ],
         ["0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8",
         ["0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56","0x2170Ed0880ac9A755fd29B2688956BD959F933F8"], //busd to eth
         tokens(20)
         ]
        ]
        await dexAggregatorInstance.connect(addr1).swap(desc,tokens(1));
    })
})