//SPDX-License-Identifier: UNLINCENSED

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";

interface IPancakeRouter01{
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn, 
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

contract DexAggregator is Ownable{

    mapping(address => bool) public whitelistedRouterAddress;

    struct SwapDescription {
        address routerAddress;
        address[] pathOfTokens;
        uint256 minOutputAmount;
    }

    function addToWhiteListedRouterAddress(address _routerAddress) external onlyOwner{
        whitelistedRouterAddress[_routerAddress] = true;
    }

    function removeFromWhiteListedRouterAddress(address _routerAddress) external onlyOwner{
        whitelistedRouterAddress[_routerAddress] = false;
    }

    function swap(SwapDescription[] calldata desc, uint256 inputAmount) external returns (uint[] memory amounts){
        for(uint i = 0; i < desc.length; i++){
            _prevalidateSwapParameters(desc[i]);
            uint[] memory amountsOut = IPancakeRouter01(desc[i].routerAddress).getAmountsOut(inputAmount, desc[i].pathOfTokens);
            (amounts) = IPancakeRouter01(desc[i].routerAddress).swapExactTokensForTokens(
            inputAmount, 
            amountsOut[1], 
            desc[i].pathOfTokens, 
            msg.sender, 
            block.timestamp+100
        );
        inputAmount = amountsOut[1];

        }
        
    }

    function _prevalidateSwapParameters (SwapDescription calldata desc) internal view {
        require(whitelistedRouterAddress[desc.routerAddress], "Invalid Router Address");
        require(desc.pathOfTokens.length > 2, "Invalid Path length");
        require(desc.minOutputAmount > 0,"Invalid Amounts");
    }

}