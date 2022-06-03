const { expect, assert } = require("chai");
const { waffle} = require("hardhat");
const provider = waffle.provider;
const { ethers, BigNumber } = require("ethers");
const { formatEther } = require("ethers/lib/utils");


const GiveTime = () => {
    const time = Math.round(new Date().getTime() / 1000); //convert to seconds
    const Add = 20 * 600000; //Add minutes
    const FinalTime = time + Add;
    return FinalTime;
  };
const tokens = (n) => {
    const x = ethers.utils.parseEther(n.toString());
    return x;
}
const ONE = ethers.BigNumber.from(1);
const TWO = ethers.BigNumber.from(2);
const sqrt = (value) => {
    x = ethers.BigNumber.from(value);
    let z = x.add(ONE).div(TWO);
    let y = x;
    while (z.sub(y).isNegative()) {
        y = z;
        z = x.div(z).add(z).div(TWO);
    }
    return y;
}

describe('Exo-Swap contracts',() =>{
    let deployer,addr1,addr2,addr3,addr4,addr5,addr6;
    let zeroAddress = "0x0000000000000000000000000000000000000000"
    
    beforeEach(async() =>{
        [deployer,addr1,addr2,addr3,addr4,addr5,addr6] = await hre.ethers.getSigners();

        exo = await hre.ethers.getContractFactory("Token");
        ExoInstance = await exo.connect(addr1).deploy("exo","EXO");
        exoAddress = ExoInstance.address;

        BUSDInstance = await hre.ethers.getContractAt("Token","0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"); //BUSD
        busdAddress = BUSDInstance.address;

        token1Instance =await hre.ethers.getContractAt("Token","0x55d398326f99059fF775485246999027B3197955"); //USDT
        token1Address = token1Instance.address;

        token2Instance = await hre.ethers.getContractAt("Token","0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d"); //USDC
        token2Address = token2Instance.address;

        token3Instance = await hre.ethers.getContractAt("Token","0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3"); //DAI
        token3Address = token3Instance.address;

        WBNBInstance = await hre.ethers.getContractAt("WBNB","0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c")
        WBNBAddress = WBNBInstance.address;

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: ["0xF977814e90dA44bFA03b6295A0616a897441aceC"],
        });
        
        const impersonate0 = await hre.ethers.getSigner("0xF977814e90dA44bFA03b6295A0616a897441aceC");
        const impersonate1 = await hre.ethers.getSigner("0xF977814e90dA44bFA03b6295A0616a897441aceC");
        const impersonate2 = await hre.ethers.getSigner("0xF977814e90dA44bFA03b6295A0616a897441aceC");
        const impersonate3 = await hre.ethers.getSigner("0xF977814e90dA44bFA03b6295A0616a897441aceC");

        await BUSDInstance.connect(impersonate0).transfer(addr1.address,await BUSDInstance.balanceOf(impersonate0.address))
        await token1Instance.connect(impersonate1).transfer(addr1.address,await token1Instance.balanceOf(impersonate1.address))
        await token2Instance.connect(impersonate2).transfer(addr1.address,await token2Instance.balanceOf(impersonate2.address))
        await token3Instance.connect(impersonate3).transfer(addr1.address,await token3Instance.balanceOf(impersonate2.address))
        
        await hre.network.provider.request({
            method: "hardhat_stopImpersonatingAccount",
            params: ["0xF977814e90dA44bFA03b6295A0616a897441aceC"],
        }); 

        //addr6 will be the treasury
        exoReferrals = await hre.ethers.getContractFactory("ExoReferral");
        exoReferralsInstance = await exoReferrals.deploy(addr6.address,"exoReferrals","EXOREFERRALS",1000,30,86400,false);
        exoReferralsAddress = exoReferralsInstance.address;

        supplementaryFee = await hre.ethers.getContractFactory("SupplementaryFee");
        supplementaryFeeInstance = await supplementaryFee.deploy();
        supplementaryFeeAddress = supplementaryFeeInstance.address;

        baseFeeVault = await hre.ethers.getContractFactory("BaseFeeVault");
        baseFeeVaultInstance = await baseFeeVault.deploy();
        baseFeeVaultAddress = baseFeeVaultInstance.address;

        await exoReferralsInstance.toggleAllowedAddresses(supplementaryFeeAddress);
        await supplementaryFeeInstance.setExoReferrals(exoReferralsAddress);

        jackpot = await hre.ethers.getContractFactory("Jackpot");
        jackpotInstance = await jackpot.deploy([busdAddress],["0xcBb98864Ef56E9042e7d2efef76141f15731B82f"]); //BUSD
        jackpotAddress = jackpotInstance.address;

        buybackFee = await hre.ethers.getContractFactory("ExoBuyBack");
        buybackFeeInstance = await buybackFee.deploy(exoAddress);
        buybackFeeAddress = buybackFeeInstance.address;

        //0xcBb98864Ef56E9042e7d2efef76141f15731B82f => chainlink mainnet busd oracle
        factory = await hre.ethers.getContractFactory("ExoFactory");
        factoryInstance = await factory.deploy(exoAddress,busdAddress,supplementaryFeeAddress,buybackFeeAddress,WBNBAddress,baseFeeVaultAddress,"0xcBb98864Ef56E9042e7d2efef76141f15731B82f");
        factoryAddress = factoryInstance.address;
        let x = await factoryInstance.INIT_CODE_PAIR_HASH();
        //console.log(x);

        router = await hre.ethers.getContractFactory("ExoRouter");
        routerInstance = await router.deploy(factoryAddress,WBNBAddress,supplementaryFeeAddress,jackpotAddress,buybackFeeAddress);
        routerAddress = routerInstance.address;

    })

    describe("checks factory for setting addresses and fees",() =>{

        let pair;
        let pairAddress;
        
        beforeEach(async() =>{
            pair = await factoryInstance.createPair(token1Address,token2Address);
            pairAddress = await factoryInstance.getPair(token1Address,token2Address);
            pairInstance = await hre.ethers.getContractAt("ExoPair",pairAddress);
        })

        describe('success',() =>{
            
            it('checks Fee Factors',async() =>{
                const fees = await pairInstance.getTotalFees();
                const treasuryfee = await pairInstance.treasuryFeeFactor();
                const buyBackFee = await pairInstance.buyBackFeeFactor();
                const jackpotFee = await pairInstance.jackPotFeeFactor();
                const dev1Fee = await pairInstance.devFeeFactor1();
                const dev2Fee = await pairInstance.devFeeFactor2();
                const lpFee = await pairInstance.lpFeeFactor();
                if(await factoryInstance.isPegEnable() == true){
                    let pegBuyBackFee = (BigNumber.from(fees).add(BigNumber.from(buyBackFee))).div(2);
                    expect(await pairInstance.getTreasuryFeeFactor()).to.equal(treasuryfee/2);
                    expect(await pairInstance.getJackpotFeeFactor()).to.equal(jackpotFee/2);
                    expect(await pairInstance.getBuybackFeeFactor()).to.equal(pegBuyBackFee);
                    expect(await pairInstance.getDev1FeeFactor()).to.equal(dev1Fee/2);
                    expect(await pairInstance.getDev2FeeFactor()).to.equal(dev2Fee/2);
                    expect(await pairInstance.getLpFeeFactor()).to.equal(lpFee/2);
                } else {
                    expect(await pairInstance.getTreasuryFeeFactor()).to.equal(treasuryfee);
                    expect(await pairInstance.getJackpotFeeFactor()).to.equal(jackpotFee);
                    expect(await pairInstance.getBuybackFeeFactor()).to.equal(buyBackFee);
                    expect(await pairInstance.getDev1FeeFactor()).to.equal(dev1Fee);
                    expect(await pairInstance.getDev2FeeFactor()).to.equal(dev2Fee);
                    expect(await pairInstance.getLpFeeFactor()).to.equal(lpFee);
                }
                
            })
            it('checks set Fee Address',async() =>{
                await factoryInstance.setFeeAddresses(pairAddress,addr1.address,addr2.address,addr3.address);
                expect(await pairInstance.treasuryAddress()).to.equal(addr1.address);
                expect(await pairInstance.jackPotAddress()).to.equal(addr2.address);
                expect(await pairInstance.buyBackAddress()).to.equal(addr3.address);
                
            })
    
            it('checks fee setters address',async() =>{
                let feeSetter1Address = await pairInstance.feeSetter1();
                let feeSetter2Address = await pairInstance.feeSetter2();
                

                if(feeSetter1Address !== zeroAddress){

                    await hre.network.provider.request({
                        method: "hardhat_impersonateAccount",
                        params: [feeSetter1Address],
                    });

                    const feeOwner1 = await hre.ethers.getSigner(feeSetter1Address);
                    await factoryInstance.connect(feeOwner1).setFeeSetter1(pairAddress,addr1.address);
                    expect(await pairInstance.feeSetter1()).to.equal(addr1.address);

                    await hre.network.provider.request({
                        method: "hardhat_stopImpersonatingAccount",
                        params: [feeSetter1Address],
                    }); 
                }

                if(feeSetter2Address !== zeroAddress){

                    await hre.network.provider.request({
                        method: "hardhat_impersonateAccount",
                        params: [feeSetter2Address],
                    });

                    const feeOwner2 = await hre.ethers.getSigner(feeSetter2Address);
                    await factoryInstance.connect(feeOwner2).setFeeSetter2(pairAddress,addr2.address);
                    expect(await pairInstance.feeSetter2()).to.equal(addr2.address);

                    await hre.network.provider.request({
                        method: "hardhat_stopImpersonatingAccount",
                        params: [feeSetter2Address],
                    }); 
                }


            })

            it('checks set dev address',async() =>{
                let feeSetter1Address = await pairInstance.feeSetter1();
                let feeSetter2Address = await pairInstance.feeSetter2();

                if(feeSetter1Address !== zeroAddress){

                    await hre.network.provider.request({
                        method: "hardhat_impersonateAccount",
                        params: [feeSetter1Address],
                    });

                    const feeOwner1 = await hre.ethers.getSigner(feeSetter1Address);
                    await factoryInstance.connect(feeOwner1).setDev1Address(pairAddress,addr5.address);
                    expect(await pairInstance.dev1Address()).to.equal(addr5.address);
                    
                    await hre.network.provider.request({
                        method: "hardhat_stopImpersonatingAccount",
                        params: [feeSetter1Address],
                    }); 
                }

                if(feeSetter2Address !== zeroAddress){

                    await hre.network.provider.request({
                        method: "hardhat_impersonateAccount",
                        params: [feeSetter2Address],
                    });

                    const feeOwner2 = await hre.ethers.getSigner(feeSetter2Address);
                    await factoryInstance.connect(feeOwner2).setDev2Address(pairAddress,addr6.address);
                    expect(await pairInstance.dev2Address()).to.equal(addr6.address);

                    await hre.network.provider.request({
                        method: "hardhat_stopImpersonatingAccount",
                        params: [feeSetter2Address],
                    }); 
                }

            })

        })

        describe('failure', () =>{
            it('reverts when zero address is given as parameter',async() =>{
                await expect(factoryInstance.setFeeAddresses(pairAddress,zeroAddress,zeroAddress,zeroAddress)).to.be.revertedWith("Invalid Address");
                await expect(factoryInstance.setDev1Address(pairAddress,zeroAddress)).to.be.revertedWith("Only Fee Setter 1 can call this function");
                await expect(factoryInstance.setDev2Address(pairAddress,zeroAddress)).to.be.revertedWith("Only Fee Setter 2 can call this function");
                await expect(factoryInstance.setFeeSetter1(pairAddress,zeroAddress)).to.be.revertedWith("Only Fee Setter 1 can call this function");
                await expect(factoryInstance.setFeeSetter2(pairAddress,zeroAddress)).to.be.revertedWith("Only Fee Setter 2 can call this function");
                await expect(factoryInstance.setFeeAddresses(zeroAddress,zeroAddress,zeroAddress,zeroAddress)).to.be.revertedWith("Exo: Pair is invalid");
                
            })
            it('reverts when other than owner and fee setters call the function', async() =>{
                await expect(factoryInstance.connect(addr1).setFeeAddresses(pairAddress,addr1.address,addr2.address,addr3.address)).to.be.revertedWith("Ownable: caller is not the owner");
                await expect(factoryInstance.connect(addr1).setDev1Address(pairAddress,addr1.address)).to.be.revertedWith("Only Fee Setter 1 can call this function");
                await expect(factoryInstance.connect(addr1).setDev2Address(pairAddress,addr1.address)).to.be.revertedWith("Only Fee Setter 2 can call this function");

            })

        })
        
        
    })

    describe("tracks the fee sent to different accounts",() =>{
        
        let amountA;
        let reserveA;
        let reserveB;
        let amountB;
        let k;
        let kLast;
        let totalSupply;
        let reserveA1;
        let reserveB1;

        beforeEach(async() =>{

            const FinalTime = GiveTime();

            //get balances
            balanceBefore1 = await token1Instance.balanceOf(addr1.address);
            balanceBefore2 = await token2Instance.balanceOf(addr1.address);

            //approve tokens to router
            await token1Instance.connect(addr1).approve(routerAddress,tokens(1000));
            await token2Instance.connect(addr1).approve(routerAddress,tokens(1000));

            //check allowance
            expect(await token1Instance.connect(addr1).allowance(addr1.address,routerAddress)).to.equal(tokens(1000));
            expect(await token2Instance.connect(addr1).allowance(addr1.address,routerAddress)).to.equal(tokens(1000));

            //add liquidity to do trade
            let tx = await routerInstance.connect(addr1).addLiquidity(token1Address,token2Address,tokens(500),tokens(500),0,0,addr1.address,GiveTime());

            let hash = (tx).hash;
            let price = (tx).gasPrice;
            let gas = (await provider.getTransactionReceipt(hash)).gasUsed;
            let gasUsed = BigNumber.from(gas).mul(BigNumber.from(price));

            console.log(`Adding Liquidity First Time Cost ${ethers.utils.formatEther(gasUsed)} BNB`)
            //get pairAddress and pairInstance
            pairAddress = await factoryInstance.getPair(token1Address,token2Address);
            pairInstance = await hre.ethers.getContractAt("ExoPair",pairAddress);

            //setFees for addresses
            await factoryInstance.setTreasuryAddress(pairAddress,addr2.address);
            await factoryInstance.setJackpotAddress(pairAddress,addr3.address);
            await factoryInstance.setBuybackAddress(pairAddress,addr4.address);

            //swapTokens and aggregate fees
            let path = [token1Address,token2Address];
            let amounts = await routerInstance.getAmountsIn(tokens(5),path);
            
            console.log("Amount of token1 to be swapped",Number(amounts[0]));
            console.log("\n");
            
            await routerInstance.connect(addr1).swapTokensForExactTokens(tokens(5),amounts[0],path,addr1.address,FinalTime);

            //quote before adding liquidity
            [reserveA,reserveB,time]= await pairInstance.getReserves();
            amountB = await routerInstance.quote(tokens(10),reserveA,reserveB);
            amountA = await routerInstance.quote(amountB,reserveB,reserveA);

            // //fetching paramters for fee calculation
            kLast = await pairInstance.kLast();
            totalSupply = await pairInstance.totalSupply();
            [reserveA1,reserveB1,time1]= await pairInstance.getReserves();

            balance0 = await token1Instance.balanceOf(pairAddress)
            balance1 = await token2Instance.balanceOf(pairAddress)

            //USDT PRICE -> 0.99950859 & USDC PRICE -> 1.0001
            console.log("pair price before adding or burning the liquidity",((0.99950859) * Number(balance0) + (1.0001) * Number(balance1)) / Number(totalSupply));
            console.log("\n");

            k = BigNumber.from(reserveA1).mul(BigNumber.from(reserveB1));
            rootKLast = sqrt(kLast);
            rootK = sqrt(k);
        })

        it('checks fee transfer',async() =>{
            
            let treasuryAddress = await pairInstance.treasuryAddress();
            let jackPotAddress = await pairInstance.jackPotAddress();
            let buyBackAddress = await pairInstance.treasuryAddress();
            let devAddress1 = await pairInstance.dev1Address();
            let devAddress2 = await pairInstance.dev2Address();

            let nFactor = Number(await pairInstance.nFactor()) 
            let dFactor = Number(await pairInstance.dFactor()) 

            console.log(nFactor)
            console.log(dFactor)
            console.log(Number(await pairInstance.getTotalFees()));

            let numerator = BigNumber.from(totalSupply).mul((BigNumber.from(rootK)).sub(BigNumber.from(rootKLast))).mul(nFactor);
            let denominator = (BigNumber.from(rootK).mul(dFactor)).add((BigNumber.from(rootKLast)).mul(nFactor));

            let result = BigNumber.from(parseInt((numerator)/(denominator)));

            console.log("calculated Total fee without LP providers fee",Number(result));
            console.log("\n");

            const balance0 = BigNumber.from(await token1Instance.balanceOf(pairAddress)).add(BigNumber.from(amountA));
            const balance1 = BigNumber.from(await token2Instance.balanceOf(pairAddress)).add(BigNumber.from(amountB));

            console.log("Balance of token0 and token1 with sum of token0 and token1 liquidity to be added",Number(balance0),Number(balance1));
            console.log("\n");

            const actualTotalSupply = BigNumber.from(totalSupply).add(result).add(BigNumber.from("4994994994994994994"));
            const token0Amount = (result.mul(balance0)).div(actualTotalSupply);
            const token1Amount = (result.mul(balance1)).div(actualTotalSupply);

            console.log("Calculated Fees in token0 and token1 terms",Number(token0Amount),Number(token1Amount))
            console.log("\n")

            // let TotalFees = await pairInstance.getTotalFees();
            // let treasuryFeeFactor = await pairInstance.getTreasuryFeeFactor();
            // let jackpotFeeFactor = await pairInstance.getJackpotFeeFactor();
            // let buybackFeeFactor = await pairInstance.getBuybackFeeFactor();
            // let dev1FeeFactor = await pairInstance.getDev1FeeFactor();
            // let dev2FeeFactor = await pairInstance.getDev2FeeFactor();

            // let treasuryLiquidity = (BigNumber.from(result).mul(BigNumber.from(treasuryFeeFactor)).div(BigNumber.from(TotalFees)));
            // let jackpotLiquidity = (BigNumber.from(result).mul(BigNumber.from(jackpotFeeFactor)).div(BigNumber.from(TotalFees)));
            // let dev1Liquidity = (BigNumber.from(result).mul(BigNumber.from(dev1FeeFactor)).div(BigNumber.from(TotalFees)));
            // let dev2Liquidity = (BigNumber.from(result).mul(BigNumber.from(dev2FeeFactor)).div(BigNumber.from(TotalFees)));
            // let buybackLiquidity = (BigNumber.from(result).mul(BigNumber.from(buybackFeeFactor)).div(BigNumber.from(TotalFees)));

            // assert.equal(Number(await pairInstance.balanceOf(treasuryAddress)),Number(treasuryLiquidity));
            // assert.equal(Number(await pairInstance.balanceOf(buyBackAddress)),Number(buybackLiquidity));
            // assert.equal(Number(await pairInstance.balanceOf(jackPotAddress)),Number(jackpotLiquidity));
            // assert.equal(Number(await pairInstance.balanceOf(devAddress1)),Number(dev1Liquidity));
            // assert.equal(Number(await pairInstance.balanceOf(devAddress2)),Number(dev2Liquidity));
            // console.log(Number(await pairInstance.balanceOf(treasuryAddress)),Number(treasuryLiquidity));
            // console.log(Number(await pairInstance.balanceOf(buyBackAddress)),Number(buybackLiquidity));
            // console.log(Number(await pairInstance.balanceOf(jackPotAddress)),Number(jackpotLiquidity));
            // console.log(Number(await pairInstance.balanceOf(devAddress1)),Number(dev1Liquidity));
            // console.log(Number(await pairInstance.balanceOf(devAddress2)),Number(dev2Liquidity));

            //add liquidity
            let tx = await routerInstance.connect(addr1).addLiquidity(token1Address,token2Address,amountA,amountB,0,0,addr1.address,GiveTime());
            let hash = (tx).hash;
            let price = (tx).gasPrice;
            let gas = (await provider.getTransactionReceipt(hash)).gasUsed;
            let gasUsed = BigNumber.from(gas).mul(BigNumber.from(price));

            console.log(`Adding Liquidity Second Time Cost ${ethers.utils.formatEther(gasUsed)} BNB`)
            tx = await baseFeeVaultInstance.withdrawBaseFees(pairAddress);
            hash = (tx).hash;
            price = (tx).gasPrice;
            gas = (await provider.getTransactionReceipt(hash)).gasUsed;
            gasUsed = BigNumber.from(gas).mul(BigNumber.from(price));

            console.log(`Cost to withdraw base fees in token0 and token1 terms ${ethers.utils.formatEther(gasUsed)} BNB`)

            //let path = [token1Address,token2Address];
            //let amounts = await routerInstance.getAmountsIn(tokens(5),path);
            //console.log(Number(amounts[0]));

            
            // //remove liquidity
            // const _bal = await pairInstance.balanceOf(addr1.address);
            // await pairInstance.connect(addr1).approve(routerAddress,_bal);
            // await routerInstance.connect(addr1).removeLiquidity(token1Address,token2Address,_bal,0,0,addr1.address,GiveTime());
            // await baseFeeVaultInstance.withdrawBaseFees(pairAddress);

            // totalSupply = await pairInstance.totalSupply();
            // let _balance0 = await token1Instance.balanceOf(pairAddress)
            // let _balance1 = await token2Instance.balanceOf(pairAddress)

            // console.log("pair price",((0.99950859) * Number(_balance0) + (1.0001) * Number(_balance1)) / Number(totalSupply));

        })

    })

    describe('checks all swap functionalities',() =>{

        beforeEach(async() =>{


            // await hre.network.provider.request({
            //     method: "hardhat_impersonateAccount",
            //     params: ["0xDb56a71Fd52004dAcb5DD5c4945A77C7CB97eDE4"],
            // });
            // const impersonate = await hre.ethers.getSigner("0xDb56a71Fd52004dAcb5DD5c4945A77C7CB97eDE4");
            // await token1Instance.connect(impersonate).transfer(addr1.address,await token1Instance.balanceOf(impersonate.address))
            // await hre.network.provider.request({
            //     method: "hardhat_stopImpersonatingAccount",
            //     params: ["0xDb56a71Fd52004dAcb5DD5c4945A77C7CB97eDE4"],
            // }); 

            await WBNBInstance.connect(addr1).deposit({
                value: ethers.utils.parseEther("100.0")
            });

            await ExoInstance.connect(addr1).approve(routerAddress,tokens(10000));
            await BUSDInstance.connect(addr1).approve(routerAddress,tokens(10000));
            await token1Instance.connect(addr1).approve(routerAddress,tokens(10000));
            await token2Instance.connect(addr1).approve(routerAddress,tokens(10000));
            await WBNBInstance.connect(addr1).approve(routerAddress,tokens(100));

            expect(await ExoInstance.connect(addr1).allowance(addr1.address,routerAddress)).to.equal(tokens(10000));
            expect(await token2Instance.connect(addr1).allowance(addr1.address,routerAddress)).to.equal(tokens(10000));
            expect(await WBNBInstance.connect(addr1).allowance(addr1.address,routerAddress)).to.equal(tokens(100));


            await routerInstance.connect(addr1).addLiquidity(exoAddress,busdAddress,tokens(100),tokens(1000),0,0,addr1.address,GiveTime());
            await routerInstance.connect(addr1).addLiquidityETH(exoAddress,tokens(40),0,tokens(1),addr1.address,GiveTime(),{value: ethers.utils.parseEther("0.5")});
            await routerInstance.connect(addr1).addLiquidity(token1Address,token2Address,tokens(10),tokens(10),0,0,addr1.address,GiveTime());
            await routerInstance.connect(addr1).addLiquidity(token1Address,exoAddress,tokens(1000),tokens(1000),0,0,addr1.address,GiveTime());
            await routerInstance.connect(addr1).addLiquidity(WBNBAddress,token2Address,tokens(10),tokens(100),0,0,addr1.address,GiveTime());
            //await routerInstance.connect(addr1).addLiquidityETH(token2Address,tokens(10),0,tokens(1),addr1.address,GiveTime(),{value: ethers.utils.parseEther("1.0")});

        })
        it('checks the swapExactTokensForTokens',async() =>{
            let path = [exoAddress,busdAddress];
            let amounts = await routerInstance.getActualAmountsOut(tokens(2),path);
            let balance1 = await BUSDInstance.balanceOf(addr1.address);
            const pair = await factoryInstance.getPair(exoAddress,busdAddress);
            await jackpotInstance.changeNumberOfJackpotTickets(pair,1);
            await jackpotInstance.changeUsdValueForEligibleTrade(pair,tokens(1)); 
            
            let tx = await routerInstance.connect(addr1).swapExactTokensForTokens(tokens(2),amounts[amounts.length - 1],path,addr1.address,GiveTime());
            let hash = (tx).hash;
            let price = (tx).gasPrice;
            let gas = (await provider.getTransactionReceipt(hash)).gasUsed;
            let gasUsed = BigNumber.from(gas).mul(BigNumber.from(price));
            let result = BigNumber.from(balance1).add(BigNumber.from(amounts[amounts.length - 1]));
            console.log("\n");
            console.log("Calculated Number of tickets for first token in trade",ethers.utils.formatEther(await jackpotInstance.getNoOfJackPotTickets(pair,exoAddress,tokens(2))))
            console.log("Calculated Number of tickets for second token in trade",ethers.utils.formatEther(await jackpotInstance.getNoOfJackPotTickets(pair,busdAddress,amounts[amounts.length - 1])))
            console.log("Actual Number of tickets minted in trade",ethers.utils.formatEther(await jackpotInstance.balanceOf(addr1.address)));
            console.log("\n");
            console.log(`Transaction Price and Gas ${price} ${gas}`);
            console.log(`Transaction Cost ${ethers.utils.formatEther(gasUsed)} BNB`)
            assert.equal(Number(await BUSDInstance.balanceOf(addr1.address)),Number(result));

        })

        it('checks the swapTokensForExactTokens',async() =>{
            let path = [token1Address,token2Address];
            let amounts = await routerInstance.getAmountsIn(tokens(1),path);
            let balance1 = await token2Instance.balanceOf(addr1.address);
            let tx = await routerInstance.connect(addr1).swapTokensForExactTokens(tokens(1),amounts[0],path,addr1.address,GiveTime());
            let hash = (tx).hash;
            let price = (tx).gasPrice;
            let gas = (await provider.getTransactionReceipt(hash)).gasUsed;
            let gasUsed = BigNumber.from(gas).mul(BigNumber.from(price));
            console.log(`Transaction Cost ${ethers.utils.formatEther(gasUsed)} BNB`)
            let result = BigNumber.from(balance1).add(BigNumber.from(tokens(1)));
            assert.equal(Number(await token2Instance.balanceOf(addr1.address)),Number(result));
        })

        it('checks the swapExactETHForTokens',async() =>{
            let path = [WBNBAddress,token2Address];
            let amounts = await routerInstance.getActualAmountsOut(tokens(1),path);
            let balance1 = await token2Instance.balanceOf(addr1.address);
            let tx = await routerInstance.connect(addr1).swapExactETHForTokens(amounts[amounts.length - 1],path,addr1.address,GiveTime(),{value: ethers.utils.parseEther("1")});
            let hash = (tx).hash;
            let price = (tx).gasPrice;
            let gas = (await provider.getTransactionReceipt(hash)).gasUsed;
            let gasUsed = BigNumber.from(gas).mul(BigNumber.from(price));
            console.log(`Transaction Cost ${ethers.utils.formatEther(gasUsed)} BNB`)
            let result = BigNumber.from(balance1).add(BigNumber.from(amounts[amounts.length -1]));
            assert.equal(Number(await token2Instance.balanceOf(addr1.address)),Number(result));

        })

        it('checks the swapTokensForExactETH',async() =>{
            let path = [token2Address,WBNBAddress];
            let amounts = await routerInstance.getAmountsIn(tokens(1),path);
            let balance1 = await provider.getBalance(addr1.address);
            let tx = await routerInstance.connect(addr1).swapTokensForExactETH(tokens(1),amounts[0],path,addr1.address,GiveTime());
            let hash = (tx).hash;
            let price = (tx).gasPrice;
            let gas = (await provider.getTransactionReceipt(hash)).gasUsed;
            let gasUsed = BigNumber.from(gas).mul(BigNumber.from(price));
            console.log(`Transaction Cost ${ethers.utils.formatEther(gasUsed)} BNB`)
            let result = BigNumber.from(balance1).add(BigNumber.from(tokens(1))).sub(BigNumber.from(gasUsed));
            assert.equal(Number(await provider.getBalance(addr1.address)),Number(result));
        
        })

        it('checks the swapExactTokensForETH',async() =>{
            let path = [token2Address,WBNBAddress];
            let amounts = await routerInstance.getActualAmountsOut(tokens(1),path);
            let balance1 = await provider.getBalance(addr1.address);
            let tx = await routerInstance.connect(addr1).swapExactTokensForETH(tokens(1),amounts[amounts.length - 1],path,addr1.address,GiveTime());
            let hash = (tx).hash;
            let price = (tx).gasPrice;
            let gas = (await provider.getTransactionReceipt(hash)).gasUsed;
            let gasUsed = BigNumber.from(gas).mul(BigNumber.from(price));
            console.log(`Transaction Cost ${ethers.utils.formatEther(gasUsed)} BNB`)
            let result = BigNumber.from(balance1).add(BigNumber.from(amounts[amounts.length - 1])).sub(BigNumber.from(gasUsed));
            assert.equal(Number(await provider.getBalance(addr1.address)),Number(result));

        })

        it('checks the swapETHForExactTokens',async() =>{
            let path = [WBNBAddress,token2Address];
            let amounts = await routerInstance.getAmountsIn(tokens(1),path);
            let balance1 = await token2Instance.balanceOf(addr1.address);
            let tx = await routerInstance.connect(addr1).swapETHForExactTokens(tokens(1),path,addr1.address,GiveTime(),{value: amounts[0]});
            let hash = (tx).hash;
            let price = (tx).gasPrice;
            let gas = (await provider.getTransactionReceipt(hash)).gasUsed;
            let gasUsed = BigNumber.from(gas).mul(BigNumber.from(price));
            console.log(`Transaction Cost ${ethers.utils.formatEther(gasUsed)} BNB`)
            let result = BigNumber.from(balance1).add(BigNumber.from(tokens(1)));
            assert.equal(Number(await token2Instance.balanceOf(addr1.address)),Number(result));

        })

        it('checks the swapExactTokensForTokensSupportingFeeOnTransferTokens',async() =>{
            let path = [token1Address,token2Address];
            let amounts = await routerInstance.getActualAmountsOut(tokens(1),path);
            let balance1 = await token2Instance.balanceOf(addr1.address);
            let tx = await routerInstance.connect(addr1).swapExactTokensForTokensSupportingFeeOnTransferTokens(tokens(1),amounts[amounts.length - 1],path,addr1.address,GiveTime());
            let hash = (tx).hash;
            let price = (tx).gasPrice;
            let gas = (await provider.getTransactionReceipt(hash)).gasUsed;
            let gasUsed = BigNumber.from(gas).mul(BigNumber.from(price));
            console.log(`Transaction Cost ${ethers.utils.formatEther(gasUsed)} BNB`)
            let result = BigNumber.from(balance1).add(BigNumber.from(amounts[amounts.length - 1]));
            assert.equal(Number(await token2Instance.balanceOf(addr1.address)),Number(result));
        })

        it('checks the swapExactETHForTokensSupportingFeeOnTransferTokens',async() =>{
            let path = [WBNBAddress,token2Address];
            let amounts = await routerInstance.getActualAmountsOut(tokens(1),path);
            let balance1 = await token2Instance.balanceOf(addr1.address);
            let tx = await routerInstance.connect(addr1).swapExactETHForTokensSupportingFeeOnTransferTokens(amounts[amounts.length - 1],path,addr1.address,GiveTime(),{ value: ethers.utils.parseEther("1")});
            let hash = (tx).hash;
            let price = (tx).gasPrice;
            let gas = (await provider.getTransactionReceipt(hash)).gasUsed;
            let gasUsed = BigNumber.from(gas).mul(BigNumber.from(price));
            console.log(`Transaction Cost ${ethers.utils.formatEther(gasUsed)} BNB`)
            let result = BigNumber.from(balance1).add(BigNumber.from(amounts[amounts.length-1]));
            assert.equal(Number(await token2Instance.balanceOf(addr1.address)),Number(result));
        })

        it('checks the swapExactTokensForETHSupportingFeeOnTransferTokens',async() =>{
         let path = [token2Address,WBNBAddress];
         let amounts = await routerInstance.getActualAmountsOut(tokens(1),path);
         let balance1 = await provider.getBalance(addr1.address);   
         let tx = await routerInstance.connect(addr1).swapExactTokensForETHSupportingFeeOnTransferTokens(tokens(1),amounts[amounts.length - 1],path,addr1.address,GiveTime());
         let hash = (tx).hash;
         let price = (tx).gasPrice;
         let gas = (await provider.getTransactionReceipt(hash)).gasUsed;
         let gasUsed = BigNumber.from(gas).mul(BigNumber.from(price));
         console.log(`Transaction Cost ${ethers.utils.formatEther(gasUsed)} BNB`)
         let result = BigNumber.from(balance1).add(BigNumber.from(amounts[amounts.length - 1])).sub(BigNumber.from(gasUsed));
         assert.equal(Number(await provider.getBalance(addr1.address)),Number(result));
         
        })

    })

    describe('checks supplementary contract',() =>{
        it('checks router is set during deployment ',async() =>{
            expect(await supplementaryFeeInstance.router()).to.equal(routerAddress);
            
        })
        it('checks factory is set during deployment',async() =>{
            expect(await supplementaryFeeInstance.factory()).to.equal(factoryAddress);
        })
    })

    describe('tracks supplementary fees',() =>{
        let amounts;
        let token1reserves;
        let token2reserves;
        let pairAddress;
        let pairInstance;
        beforeEach(async() =>{
            //giving approval to router contract
            await token1Instance.connect(addr1).approve(routerAddress,tokens(10000));
            await token2Instance.connect(addr1).approve(routerAddress,tokens(10000));
            //checking allowance given to router
            expect(await token1Instance.connect(addr1).allowance(addr1.address,routerAddress)).to.equal(tokens(10000));
            expect(await token2Instance.connect(addr1).allowance(addr1.address,routerAddress)).to.equal(tokens(10000));
            //creating pair for token1 and token2
            await factoryInstance.connect(addr1).createPair(token1Address,token2Address);
            //adding liquidity for token1 and token2
            await routerInstance.connect(addr1).addLiquidity(token1Address,token2Address,tokens(10),tokens(10),0,0,addr1.address,GiveTime());
            //fetching pairAddress and creating instance
            pairAddress = await factoryInstance.getPair(token1Address,token2Address);
            pairInstance = await hre.ethers.getContractAt("ExoPair",pairAddress);
            //fetching reserves of token1 and token2 pair
            token1reserves = await token1Instance.balanceOf(pairAddress);
            token2reserves = await token2Instance.balanceOf(pairAddress);
            //fetching path and amountsIn parameters for swap
            let path = [token1Address,token2Address];
            amounts = await routerInstance.getAmountsIn(tokens(1),path);
            //swaping
            await routerInstance.connect(addr1).swapTokensForExactTokens(tokens(1),amounts[0],path,addr1.address,GiveTime());
            
        })
        it('checks the fee sent to supplementary contract',async() =>{
            //fetching reserves after swap
            let token1ReserveAfter = BigNumber.from(token1reserves).add(BigNumber.from(amounts[0]));
            let token2ReserveAfter = BigNumber.from(token2reserves).sub(BigNumber.from(tokens(1)))
            //calculating supplementary fee after swap
            let token1Fee = BigNumber.from(token1ReserveAfter).sub(BigNumber.from(await token1Instance.balanceOf(pairAddress)));
            let token2Fee = BigNumber.from(token2ReserveAfter).sub(BigNumber.from(await token2Instance.balanceOf(pairAddress)));
            //checking the sell tax fee calculation
            let sellPercent = await routerInstance.retTotalSellFee(pairAddress,token1Address);
            let intialAmountTax = (BigNumber.from(amounts[0]).mul(BigNumber.from(sellPercent))).div(BigNumber.from(tokens(1)));
            expect(token1Fee).to.equal(intialAmountTax);
            //checking buy tax fee calculation
            let buyPercent = await routerInstance.retTotalBuyFee(pairAddress,token2Address);
            let token1AmountAfterTax = ethers.utils.formatEther(BigNumber.from(amounts[0]).sub(BigNumber.from(token1Fee)));
            let finalAmountWithoutTaxDeducted = await routerInstance.getAmountOut(pairAddress,tokens(token1AmountAfterTax),token1reserves,token2reserves);
            let finalAmountTax = (BigNumber.from(finalAmountWithoutTaxDeducted).mul(BigNumber.from(buyPercent))).div(BigNumber.from(tokens(1)));
            expect(token2Fee).to.equal(finalAmountTax);
            //checking whether the exact fetched fees are sent to supplementary contract
            expect(await token1Instance.balanceOf(supplementaryFeeAddress)).to.equal(intialAmountTax);
            expect(await token2Instance.balanceOf(supplementaryFeeAddress)).to.equal(finalAmountTax);
   
        })
    })

})