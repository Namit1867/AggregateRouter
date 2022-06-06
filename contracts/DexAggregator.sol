// //SPDX-License-Identifier: UNLINCENSED

// pragma solidity ^0.8.0;


// import "@openzeppelin/contracts/access/Ownable.sol";

// interface IPancakeRouter01{
//     function swapExactTokensForTokens(
//         uint amountIn,
//         uint amountOutMin,
//         address[] calldata path,
//         address to,
//         uint deadline
//     ) external returns (uint[] memory amounts);
// }

// contract DexAggregator is Ownable{

//     mapping(address => bool) public whitelistedRouterAddress;

//     struct SwapDescription {
//         address routerAddress;
//         address[] pathOfTokens;
//         uint256 inputAmount;
//         uint256 minOutputAmount;
//     }

//     function addToWhiteListedRouterAddress(address _routerAddress) external onlyOwner{
//         whitelistedRouterAddress[_routerAddress] = true;
//     }

//     function removeFromWhiteListedRouterAddress(address _routerAddress) external onlyOwner{
//         whitelistedRouterAddress[_routerAddress] = false;
//     }

//     function swap(SwapDescription[] memory desc) external returns (uint[] memory amounts){
//         _prevalidateSwapParameters(desc[0]);
//         (amounts) = IPancakeRouter01(desc.routerAddress).swapExactTokensForTokens(
//             desc.inputAmount, 
//             desc.minOutputAmount, 
//             desc.pathOfTokens, 
//             msg.sender, 
//             block.timestamp+100
//         );
//     }

//     function _prevalidateSwapParameters (SwapDescription calldata desc) internal view {
//         require(whitelistedRouterAddress[desc.routerAddress], "Invalid Router Address");
//         require(desc.pathOfTokens.length > 2, "Invalid Path length");
//         require((desc.inputAmount > 0) && (desc.minOutputAmount > 0),"Invalid Amounts");
//     }

// }