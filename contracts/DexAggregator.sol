//SPDX-License-Identifier: UNLINCENSED

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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
    using SafeERC20 for IERC20;

    address treasuryAddress;
    uint256 exoFees; //390

    mapping(address => bool) public whitelistedRouterAddress;
    mapping(address => uint256) public routerFees;

    struct SwapDescription {
        address routerAddress;
        address[] pathOfTokens;
        uint256 minOutputAmount;
    }

    constructor (address _treasuryAddress,uint256 _exoFees) {
        treasuryAddress = _treasuryAddress;
        exoFees = _exoFees;
    }

    function addToWhiteListedRouterAddress(address _routerAddress) external onlyOwner{
        whitelistedRouterAddress[_routerAddress] = true;
    }

    function removeFromWhiteListedRouterAddress(address _routerAddress) external onlyOwner{
        whitelistedRouterAddress[_routerAddress] = false;
    }

    function addRouterFees(address _routerAddress, uint256 _fees) external onlyOwner {
        routerFees[_routerAddress] = _fees;
    }

    function swap(SwapDescription[] calldata desc, uint256 inputAmount) external returns (uint[] memory amounts){

        IERC20(desc[0].pathOfTokens[0]).safeTransferFrom(msg.sender,address(this),inputAmount);

        for(uint i = 0; i < desc.length; i++){

            _prevalidateSwapParameters(desc[i]);

            IERC20(desc[i].pathOfTokens[0]).safeApprove(
                desc[i].routerAddress,
                0
            );

            IERC20(desc[i].pathOfTokens[0]).safeIncreaseAllowance(
                desc[i].routerAddress,
                inputAmount
            );

            uint feeAmount = _getFeeAmountAndTransfer(desc[i], inputAmount, desc[i].pathOfTokens[0]);

            uint[] memory amountsOut = IPancakeRouter01(desc[i].routerAddress).getAmountsOut(
                inputAmount-feeAmount, 
                desc[i].pathOfTokens
            );

            (amounts) = IPancakeRouter01(desc[i].routerAddress).swapExactTokensForTokens(
            (inputAmount-feeAmount), 
            _slippage(amountsOut[amountsOut.length-1]), 
            desc[i].pathOfTokens, 
            address(this), 
            block.timestamp+100
        );

        if(inputAmount > amounts[amounts.length-2]){
            uint remaining = inputAmount - amounts[amounts.length-2];
            IERC20(desc[i].pathOfTokens[0]).safeTransfer(msg.sender,remaining);
        }
        
        inputAmount = amounts[amounts.length-1];
        }
        
    }

    function _prevalidateSwapParameters (SwapDescription calldata desc) internal view {
        require(whitelistedRouterAddress[desc.routerAddress], "Invalid Router Address");
        require(desc.pathOfTokens.length >= 2, "Invalid Path length");
        require(desc.minOutputAmount > 0,"Invalid Amounts");
    }

    function _slippage(uint256 amount) internal pure returns(uint256) {
        uint amountAfterSlippage = (amount*95)/100;
        return amountAfterSlippage;
    }

    function _getFeeAmountAndTransfer(SwapDescription calldata desc, uint256 _amount, address _token) internal  returns (uint256){
        uint256 fee = routerFees[desc.routerAddress];
        if(fee < exoFees){
            uint feeDifference = exoFees - fee;
            uint256 feeAmount = _amount - ((_amount*feeDifference)/1000);
            IERC20(_token).safeTransfer(treasuryAddress,feeAmount);
            return feeAmount;
        } else {
            uint256 feeAmount = _amount - ((_amount*fee)/1000);
            IERC20(_token).safeTransfer(treasuryAddress,feeAmount);
            return feeAmount;
        }
        
    }

}