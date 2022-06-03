// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


interface IPancakeRouter01 {
    
    function factory() external pure returns (address);

    function WBNB() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getActualAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IPancakePair {
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

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

interface IWBNB {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

contract ExoBuyBack is Ownable {

    using SafeERC20 for IERC20;

    address public exoRouter;

    address public immutable convertedToken; //EXO token
    
    uint256 public slippageFactor = 950; // 5% default slippage tolerance

    uint256 public constant slippageFactorUL = 995;

    constructor(address exo) {
        convertedToken = exo;
    }
    
    event SlippageChanged(uint256 oldSlippage,uint256 newSlippage);

   /*
    * Change Slippage Factor
    */ 
    function changeSlippageFactor(uint256 newSlippage) external onlyOwner {
        
        require(newSlippage <= slippageFactorUL,"New Slippage is above UL");
        uint256 oldSlippage = slippageFactor;
        slippageFactor = newSlippage;
        emit SlippageChanged(oldSlippage,newSlippage);
        
    }

    function setExoRouter(address _router) external {
        if(exoRouter == address(0)){
            exoRouter = _router;
        }
        else{
            setRouterInternal(_router);
        }
    }

    function setRouterInternal(address _router) internal onlyOwner {
        exoRouter = _router;
    }

    
   /*
    * Safe Remove Liquidity
    */ 
    function _safeRemoveLiquidity(
        address tokenA,
        address tokenB,
        address _routerAddress,
        uint256 _amount,
        uint256 amountAmin,
        uint256 amountBmin,
        address _to,
        uint256 _deadline
    ) internal virtual returns(uint256 amountA, uint256 amountB) {
        (amountA,amountB) = IPancakeRouter02(_routerAddress)
            .removeLiquidity(
            tokenA,
            tokenB,
            _amount,
            amountAmin,
            amountBmin,
            _to,
            _deadline
        );
    }
    
    
   /*
    * Function to withdraw stuck tokens
    */
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == address(0)) {
                qty = address(this).balance;
                (bool success , ) = (owner()).call{value: qty}(new bytes(0));
                require(success,"BNB transfer fail");
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }
    
    
    function convertLpOutput(address wantAddress,address routerAddress,address[] memory _path1,address[] memory _path2) public view returns(uint256 output) {
        

        uint256 wantAmount = IPancakePair(wantAddress).balanceOf(address(this));

        address token0 = IPancakePair(wantAddress).token0();
        address token1 = IPancakePair(wantAddress).token1();
        
        uint256 wantAddToken0Bal = IERC20(token0).balanceOf(wantAddress);
        uint256 wantAddToken1Bal = IERC20(token1).balanceOf(wantAddress);
        uint256 wantTotalSupply = IPancakePair(wantAddress).totalSupply();
        
        uint256 token0Amt = (wantAmount * wantAddToken0Bal) / (wantTotalSupply);
        uint256 token1Amt = (wantAmount * wantAddToken1Bal) / (wantTotalSupply);
        
        uint256[] memory amounts1;
        uint256[] memory amounts2;
             
            if (token0Amt > 0 && token1Amt > 0) {
                                
               /*
                * Check path1 length              
                * if path1 length is zero this means token0 is WBNB
                */
                if (_path1.length > 0){
                    
                    if(routerAddress != exoRouter){
                        amounts1 =
                        IPancakeRouter02(routerAddress).getAmountsOut(token0Amt, _path1);
                    }
                    else{
                        amounts1 =
                        IPancakeRouter02(routerAddress).getActualAmountsOut(token0Amt, _path1);
                    }
                
                }
                
               /*
                * Check path2 length              
                * if path2 length is zero this means token1 is WBNB
                */
                if (_path2.length > 0){
                    
                    if(routerAddress != exoRouter){
                        amounts1 =
                        IPancakeRouter02(routerAddress).getAmountsOut(token1Amt, _path2);
                    }
                    else{
                        amounts1 =
                        IPancakeRouter02(routerAddress).getActualAmountsOut(token1Amt, _path2);
                    }

                }
                
                /*
                 * Calculate token0 output amount after swap              
                 */
                 uint256 token1Amount;
                 if(_path1.length > 0)
                 token1Amount = amounts1[amounts1.length-1];
                 else
                 token1Amount = token0Amt;
            
                /*
                 * Calculate token1 output amount after swap              
                 */
                 uint256 token2Amount;
                 if(_path2.length > 0)
                 token2Amount = amounts2[amounts2.length-1];
                 else
                 token2Amount = token1Amt;
            
                 output = token1Amount + token2Amount;
            }
    }
    
   /*
    * Convert Liquidity Tokens into wbnb or bnb
    */

    address receiver;

    function convertLiquidityToken(address wantAddress,address routerAddress,address[] memory path1,address[] memory path2,address to) external onlyOwner  {
       
       receiver = to;
       
       uint256 wantAmount = IPancakePair(wantAddress).balanceOf(address(this));
        
       /*
        * Fetch token0 and token1
        */
        address token0 = IPancakePair(wantAddress).token0();
        address token1 = IPancakePair(wantAddress).token1();
       
       /*
        * Security Checks
        */
        
        require(token0 != address(0),"token0 cannot be zero");
        require(token1 != address(0),"token1 cannot be zero");
        require(token0 != token1,"token0 and token1 address is same");
        
        if(path1.length > 0){
            require((path1[path1.length - 1]) == convertedToken,"wrong path1");
        }

        if(path2.length > 0){ 
           require((path2[path2.length - 1] == convertedToken),"wrong path2");  
        }
        

       /*
        * Calculating token0 and token1 amount received on remove Liquidity
        */

        uint256 wantAddToken0Bal = IERC20(token0).balanceOf(wantAddress);
        uint256 wantAddToken1Bal = IERC20(token1).balanceOf(wantAddress);
        uint256 wantTotalSupply = IPancakePair(wantAddress).totalSupply();
        
        uint256 token0Min = (wantAmount * wantAddToken0Bal) / (wantTotalSupply);
        uint256 token1Min = (wantAmount * wantAddToken1Bal) / (wantTotalSupply);
        
        token0Min = (token0Min * slippageFactor) / (10000);
        token1Min = (token1Min * slippageFactor) / (10000);
        
       /*
        * Set Allowance to Router to zero 
        */
        IERC20(wantAddress).safeApprove(routerAddress, 0);
        
        
        /*
        * Increase Allowance to Router to given amount
        */
        IERC20(wantAddress).safeIncreaseAllowance(
            routerAddress,
            wantAmount
        );

        address _convertedToken = convertedToken;     
        
        {
           /*
            * Avoid stack too deep errors
            */
            uint256 _wantAmount = wantAmount;
            address _routerAddress = routerAddress;
            address[] memory _path1 = path1;
            address[] memory _path2 = path2;
            address _token0 = token0;
            address _token1 = token1; 
            
            
            /*
            * Remove Liquidity
            */
            (uint token0Amt, uint token1Amt) = _safeRemoveLiquidity(_token0,
                                                              _token1,
                                                              _routerAddress,
                                                              _wantAmount,
                                                              token0Min,
                                                              token1Min,
                                                              address(this),
                                                              block.timestamp +600);
                                                                                                        
           /*
            * Increase token0 and token1 allowance to router                
            * swap token0 and token1 amount into convertedToken 
            */
            
            uint256[] memory amounts1;
            uint256[] memory amounts2;
             
            if (token0Amt > 0 && token1Amt > 0) {
                                
               /*
                * Check path1 length              
                * if path1 length is zero this means token0 is the EXO token
                */
                if (_path1.length > 0){
                    
                    IERC20(_token0).safeIncreaseAllowance(
                        _routerAddress,
                        token0Amt);
                    
                    (amounts1) =_safeSwap(
                        _routerAddress,
                        token0Amt,
                        slippageFactor,
                        _path1,
                        address(this),
                        block.timestamp + 600);
                       
                    
                }

               /*
                * Check path2 length              
                * if path2 length is zero this means token1 is EXO
                */
                if (_path2.length > 0){
                   
                    (_path2[0] == _token1) ? IERC20(_token1).safeIncreaseAllowance(
                    _routerAddress,
                    type(uint).max):
                    IERC20(_token0).safeIncreaseAllowance(
                    _routerAddress,
                    type(uint).max);
                    
                 
                    (amounts2) =_safeSwap(
                        _routerAddress,
                        token1Amt,
                        slippageFactor,
                        _path2,
                        address(this),
                        block.timestamp + 600);
                    
                }

           /*
            * Calculate token0 output amount after swap              
            */
            uint256 token1Amount;
            if(_path1.length > 0)
            token1Amount = amounts1[amounts1.length-1];
            else
            token1Amount = token0Amt;
            
            /*
            * Calculate token1 output amount after swap              
            */
            uint256 token2Amount;
            if(_path2.length > 0)
            token2Amount = amounts2[amounts2.length-1];
            else
            token2Amount = token1Amt;
            
            uint256 output = token1Amount + token2Amount;
             
            address bep20Token = _convertedToken;

            output = ( output <= IERC20(convertedToken).balanceOf(address(this))) ? output : IERC20(convertedToken).balanceOf(address(this));
            
            IERC20(bep20Token).safeTransfer(receiver,output);
                
            }
            
        }
        receiver = address(0);
        
    }

    function _safeSwap(
        address _routerAddress,
        uint256 _amountIn,
        uint256 _slippageFactor,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) internal virtual returns (uint[] memory amounts){
        
        uint256 amountOut;
        if(_routerAddress != exoRouter){
            amounts =
            IPancakeRouter02(_routerAddress).getAmountsOut(_amountIn, _path);
            amountOut = amounts[amounts.length - 1];
        }
       else{
            amounts =
            IPancakeRouter02(_routerAddress).getActualAmountsOut(_amountIn, _path);
            amountOut = amounts[amounts.length - 1];
        }

        amounts = IPancakeRouter02(_routerAddress)
            .swapExactTokensForTokens(
            _amountIn,
            (amountOut * _slippageFactor) / 1000,
            _path,
            _to,
            _deadline
        );
    }
}