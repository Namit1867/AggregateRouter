//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IExoPair {

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function getTotalFees() external view returns (uint256);

    function feeSetter1() external view returns(address);
    function feeSetter2() external view returns(address);

    function setTreasuryFee(uint256 _treasuryFeeFactor) external;
    function setBuybackFee(uint256 _buyBackFeeFactor) external;
    function setJackpotFee(uint256 _jackPotFeeFactor) external;
    function setDevFee1(uint256 _devFeeFactor1) external;
    function setDevFee2(uint256 _devFeeFactor2) external;
    function setLpFee(uint256 _lpFeeFactor) external;

    function setFeeSetter1(address _lpFeeFactorAddress) external;
    function setFeeSetter2(address _lpFeeFactorAddress) external;

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface Oracle {

    function latestRoundData() external view returns(uint80, int256, uint256, uint256, uint80);
    
}

contract Jackpot is ERC20("exoPlay Ticket", "EXOPLAY"), Ownable {

    address public router;

    mapping(address => address) public tokenOracles; //chainlink price oracles of tokens

    mapping(address => uint) public noOfJackpotTickets; //pair -> no. of tickets to be given if trade is eligible

    mapping(address => uint) public tradeValueEligibleInUsd; //pair -> trade value in usd eligible for jackpot ticket

    modifier onlyRouter {
        require(router != address(0),"Router Address cannot be Zero");
        require(msg.sender == router,"Caller is not the router");
        _;
    }

    function setRouter(address _router) external {
        if(router == address(0)){
            router = _router;
        }
        else{
            setRouterInternal(_router);
        }
    }

    function setRouterInternal(address _router) internal onlyOwner {
        router = _router;
    }

    constructor (address[] memory tokens,address[] memory oracles) {

        require((tokens.length == oracles.length),"Length is not equal");

        for(uint i = 0 ; i < tokens.length ; i++) {
            tokenOracles[tokens[i]] = oracles[i];
        }
        
    }

    function addNewEligibleToken(address[] memory tokens,address[] memory oracles) external onlyOwner {

        require((tokens.length == oracles.length),"Length is not equal");
        for(uint i = 0 ; i < tokens.length ; i++) {
            tokenOracles[tokens[i]] = oracles[i];
        }

    }

    function removeEligibleTokens(address[] memory tokens) external onlyOwner {

        for(uint i = 0 ; i < tokens.length ; i++) {
            require(tokenOracles[tokens[i]] != address(0),"Oracle does not exist for some token");
            tokenOracles[tokens[i]] = address(0);
        }

    }


    function isTokenEligible(address token) public view returns (bool present){
        present = (tokenOracles[token] != address(0)) ? true : false;
    }


    function isEligiblePair(address pair) public view returns (bool){

        address token0 = IExoPair(pair).token0();
        bool present0 = tokenOracles[token0] != address(0); 

        address token1 = IExoPair(pair).token1();
        bool present1 = tokenOracles[token1] != address(0); 

        if(present0 || present1)
        return true;

        return false;

    }

    function changeNumberOfJackpotTickets(address pair,uint newTicketAmount) external onlyOwner {
        require(isEligiblePair(pair),"Pair is not eligible");
        noOfJackpotTickets[pair] = newTicketAmount; //it is not scaled to 18 decimals
    }

    function changeUsdValueForEligibleTrade(address pair,uint newUsdAmount) external onlyOwner {
        require(isEligiblePair(pair),"Pair is not eligible");
        tradeValueEligibleInUsd[pair] = newUsdAmount;
    }

    function mintTicketsInternal(address pair,address user,uint tradeAmount) internal returns(bool){

        uint val = tradeValueEligibleInUsd[pair];
                
        if(val > 0 && tradeAmount >= val){

            uint temp = (tradeAmount / val ) * 1e18;
            uint noOfTickets = (temp * noOfJackpotTickets[pair]);
            _mint(user,noOfTickets);
            return true;
        }
        else{
            return false;
        }

    }

    function mintTickets(
        address pair,
        address token,
        address user,
        uint tokenAmount) external onlyRouter returns(bool){

        bool success;
        success = tokenOracles[token] != address(0);

        if(success){
            (,int256 latestPrice,,,) = Oracle(tokenOracles[token]).latestRoundData();
            uint tokenPrice = uint256(latestPrice); // scaled by 8 decimals
            uint tokenUsdAmount = (tokenAmount * tokenPrice) / 1e8;
            return mintTicketsInternal(pair,user,tokenUsdAmount);
        }
        else{
            return false;
        }

    }

    function getNoOfJackPotTickets(        
        address pair,
        address token,
        uint tokenAmount) external view returns(uint){

        bool success;
        success = tokenOracles[token] != address(0);

        if(success){

            (,int256 latestPrice,,,) = Oracle(tokenOracles[token]).latestRoundData();
            uint tokenPrice = uint256(latestPrice); // scaled by 8 decimals
            uint tokenUsdAmount = (tokenAmount * tokenPrice) / 1e8;
            
            uint val = tradeValueEligibleInUsd[pair];
                
            if(val > 0 && tokenUsdAmount >= val){

            uint temp = (tokenUsdAmount / val) * 1e18;
            uint noOfTickets = (temp * noOfJackpotTickets[pair]);
            return noOfTickets;
        }
        else{
            return 0;
        }

        }
        else{
            return 0;
        }

    }
}