// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


interface IExoRouter01 {

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(address _pair, uint amountIn, uint reserveIn, uint reserveOut) external view returns (uint amountOut);
    function getAmountIn(address _pair, uint amountOut, uint reserveIn, uint reserveOut) external view returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IExoRouter02 is IExoRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


interface IExoFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);

    function suppFeeContract() external view returns(address);

}


interface IExoPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function getTotalFees() external view returns (uint256);

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

library ExoLibrary {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'ExoLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ExoLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'5f80be7affd776e624a75b5c9022b3032a39f548001a3bd7d69c9a73fd9d4286' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IExoPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'ExoLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'ExoLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(address _pair, uint amountIn, uint reserveIn, uint reserveOut) internal view returns (uint amountOut) {
        require(amountIn > 0, 'ExoLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ExoLibrary: INSUFFICIENT_LIQUIDITY');
        uint256 _totalFees = IExoPair(_pair).getTotalFees();
        uint256 afterFeeDeduction = 1000000 - (_totalFees);
        uint amountInWithFee = amountIn * afterFeeDeduction;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000000) + (amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(address _pair, uint amountOut, uint reserveIn, uint reserveOut) internal view returns (uint amountIn) {
        require(amountOut > 0, 'ExoLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ExoLibrary: INSUFFICIENT_LIQUIDITY');
        uint256 _totalFees = IExoPair(_pair).getTotalFees();
        uint256 afterFeeDeduction = 1000000 - (_totalFees);
        uint numerator = reserveIn * amountOut * 1000000;
        uint denominator = (reserveOut - amountOut) * (afterFeeDeduction);
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ExoLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        address _pair = IExoFactory(factory).getPair(path[0],path[1]);

        address suppFeeContract = IExoFactory(factory).suppFeeContract(); 

        uint buyFee; // in 1e16
        uint sellFee = retTotalSellFee(suppFeeContract,_pair,path[0]); // in 1e16

        amounts[0] = amountIn;

        uint temp = (amountIn * (uint(100e16) - sellFee) ) / (uint(100e16));

        for (uint i; i < path.length - 1; i++) {

            if(i > 0){
                _pair = IExoFactory(factory).getPair(path[i],path[i+1]);
            }

            buyFee = retTotalBuyFee(suppFeeContract,_pair,path[i+1]);
            sellFee = retTotalSellFee(suppFeeContract,_pair,path[i+1]);

            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(_pair, temp, reserveIn, reserveOut);

            if(i != (path.length - 2)){
                temp = (amounts[i + 1] * (uint(100e16) - buyFee)) / (uint(100e16));
                temp = (temp * (uint(100e16) - sellFee)) / (uint(100e16));
            }
        }
    }


    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ExoLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        address _pair = IExoFactory(factory).getPair(path[path.length - 2],path[path.length - 1]);

        address suppFeeContract = IExoFactory(factory).suppFeeContract();

        uint buyFee = retTotalBuyFee(suppFeeContract,_pair,path[path.length - 1]); // in 1e16
        uint sellFee; // in 1e16

        amounts[amounts.length - 1] = (amountOut * 100e16) / (uint(100e16) - buyFee);

        for (uint i = path.length - 1; i > 0; i--) {

            if(i < (path.length - 1)){
                _pair = IExoFactory(factory).getPair(path[i - 1],path[i]);
            }

            buyFee = retTotalBuyFee(suppFeeContract,_pair,path[i-1]);
            sellFee = retTotalSellFee(suppFeeContract,_pair,path[i-1]);

            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(_pair, amounts[i], reserveIn, reserveOut);

            if(i != 1){
                amounts[i - 1] = (amounts[i - 1] * 100e16) / (uint(100e16) - buyFee);
                amounts[i - 1] = (amounts[i - 1] * 100e16) / (uint(100e16) - sellFee);
            }
            else{
                //charge sell fee only
                amounts[i - 1] = (amounts[i - 1] * 100e16) / (uint(100e16) - sellFee);
            }
        }
    }

    function retTotalSellFee(address suppFeeContract,address pair,address token) internal view returns(uint256) {
        return ISupplementaryFee(suppFeeContract).retTotalSellFee(pair,token);
    }

    function retTotalBuyFee(address suppFeeContract,address pair,address token ) internal view returns(uint256) {
        return ISupplementaryFee(suppFeeContract).retTotalBuyFee(pair,token);
    }

}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface ISupplementaryFee {
    function setRouter(address _router) external;
    function setFactory(address _factory) external;
    function initialize(address _pair) external;
    function increment(address user,address _pair,address token,uint tax,uint amount) external;
    function retTotalSellFee(address pair,address token) external view returns(uint256);
    function retTotalBuyFee(address pair,address token) external view returns(uint256);
}

interface JackpotTicket {	
    function setRouter(address _router) external;	
    function mintTickets(	
        address pair,
        address token,
        address user,
        uint tokenAmount) external returns(bool);	
}

interface IBuyBack {	
    function setExoRouter(address _router) external;	
}

contract ExoRouter is IExoRouter02 {

    address public immutable factory;
    address public immutable WBNB;
    address public immutable suppFeeContract;
    address public immutable jackpotContract;
    address public immutable buybackContract;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'ExoRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WBNB,address _suppFeeContract,address _jackpot,address _buyback) {
        factory = _factory;
        WBNB = _WBNB;
        jackpotContract = _jackpot;
        suppFeeContract = _suppFeeContract;
        buybackContract = _buyback;
        ISupplementaryFee(_suppFeeContract).setRouter(address(this));
        JackpotTicket(_jackpot).setRouter(address(this));
        IBuyBack(_buyback).setExoRouter(address(this));
    }

    receive() external payable {
        assert(msg.sender == WBNB); // only accept ETH via fallback from the WBNB contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IExoFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IExoFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = ExoLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = ExoLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'ExoRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = ExoLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'ExoRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = ExoLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IExoPair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WBNB,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = ExoLibrary.pairFor(factory, token, WBNB);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWBNB(WBNB).deposit{value: amountETH}();
        assert(IWBNB(WBNB).transfer(pair, amountETH));
        liquidity = IExoPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = ExoLibrary.pairFor(factory, tokenA, tokenB);
        IExoPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IExoPair(pair).burn(to);
        (address token0,) = ExoLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'ExoRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'ExoRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WBNB,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWBNB(WBNB).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = ExoLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? type(uint).max : liquidity;
        IExoPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = ExoLibrary.pairFor(factory, token, WBNB);
        uint value = approveMax ? type(uint).max : liquidity;
        IExoPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WBNB,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWBNB(WBNB).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = ExoLibrary.pairFor(factory, token, WBNB);
        uint value = approveMax ? type(uint).max : liquidity;
        IExoPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
             token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    function retTotalSellFee(address pair,address token) public view returns(uint256) {
        return ExoLibrary.retTotalSellFee(suppFeeContract,pair,token);
    }

    function retTotalBuyFee(address pair,address token ) public view returns(uint256) {
        return ExoLibrary.retTotalBuyFee(suppFeeContract,pair,token);
    }

    function increment(address user,address _pair,address token,uint tax,uint amount) internal {
        ISupplementaryFee(suppFeeContract).increment(user,_pair,token,tax,amount); 
    }

    function takeSellCharge(address seller,address pair,address token,uint256 amount) internal returns(uint256) {
        
        address feeAddress = suppFeeContract;

        uint sellCharge = retTotalSellFee(pair,token); // in 1e16 and diff for token0 and token1

        if(sellCharge == 0){
            return amount;
        }

        //return amount after deducting selling charge from given amount 
        //for token0 and token1 in this pair

        if(seller == msg.sender){
            //use safetransferfrom
            uint feeAmount = (amount * sellCharge) / (uint(100e16)); 
            uint feeAddressBalBefore = IERC20(token).balanceOf(feeAddress);
            TransferHelper.safeTransferFrom(
            token, msg.sender, feeAddress, feeAmount);
            uint feeAddressBalAfter = IERC20(token).balanceOf(feeAddress);
            increment(msg.sender,pair,token,0,(feeAddressBalAfter - feeAddressBalBefore)); 
            return (amount - feeAmount);
        }
        else{
            //use transfer as seller is router in case of WBNB
            uint feeAmount = (amount * sellCharge) / (uint(100e16)); 
            TransferHelper.safeTransfer(
            token, feeAddress, feeAmount);
            increment(msg.sender,pair,token,0,feeAmount);
            return (amount - feeAmount); 
        }
    }

    function takeBuyCharge(address pair,address token,uint256 amount) internal returns(uint256) {
        
        address feeAddress = suppFeeContract; 

        uint buyCharge = retTotalBuyFee(pair,token); // in 1e16 and diff for token0 and token1

        if(buyCharge == 0){
            return amount;
        }
 
        //return amount after deducting buying charge from given amount 
        //for token0 and token1 in this pair

        uint feeAmount = (amount * buyCharge) / (uint(100e16)); 
        uint feeAddressBalBefore = IERC20(token).balanceOf(feeAddress);
        TransferHelper.safeTransfer( 
        token, feeAddress, feeAmount);
        uint feeAddressBalAfter = IERC20(token).balanceOf(feeAddress);
        increment(msg.sender,pair,token,1,(feeAddressBalAfter - feeAddressBalBefore)); 
        return (amount - feeAmount); 
        
    }

    enum SWAPTYPE{
        FIRST,  //swapExactTokensForTokens
        SECOND, //swapTokensForExactTokens *
        THIRD,  //swapExactETHForTokens
        FOURTH, //swapTokensForExactETH *
        FIFTH,  //swapExactTokensForETH
        SIXTH   //swapETHForExactTokens *
    }

    function mintJackpotTickets(	
        address pair,	
        address token,
        address user,	
        uint tokenAmount) internal returns(bool){	
        return JackpotTicket(jackpotContract).mintTickets(	
            pair,	
            token,	
            user,	
            tokenAmount	
        );	
    }

    mapping(address => bool) ticketsGiven;

    // **** SWAP ****
    function _swap(SWAPTYPE _type,uint[] memory amounts, address[] memory path, address _to) internal virtual {

        address finalReceiver = _to;
        address pair = ExoLibrary.pairFor(factory, path[0], path[1]);

        if(_type == SWAPTYPE.FIRST || _type == SWAPTYPE.SECOND || _type == SWAPTYPE.FOURTH || _type == SWAPTYPE.FIFTH){
            uint amountAfterFee = takeSellCharge(msg.sender,pair,path[0],amounts[0]);
            TransferHelper.safeTransferFrom(
            path[0], msg.sender, ExoLibrary.pairFor(factory, path[0], path[1]), amountAfterFee);
            ticketsGiven[_to] = mintJackpotTickets(pair,path[0],_to,amountAfterFee);
        }
        else if(_type == SWAPTYPE.THIRD || _type == SWAPTYPE.SIXTH){  
            uint amountAfterFee = takeSellCharge(address(this),pair,path[0],amounts[0]);
            assert(IWBNB(WBNB).transfer(ExoLibrary.pairFor(factory, path[0], path[1]), amountAfterFee));
            ticketsGiven[_to] = mintJackpotTickets(pair,path[0],_to,amountAfterFee);
        }
        

        for (uint i; i < path.length - 1; i++) {
            address[] memory _path = path;
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = ExoLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            pair = ExoLibrary.pairFor(factory,input, output);
            SWAPTYPE type_ = _type;           
            {
            address _pair = pair;
            uint receivedTokenBalBefore = IERC20(output).balanceOf(address(this));
            IExoPair(pair).swap(
                amount0Out, amount1Out, address(this), new bytes(0)
            );
            
            address _finalReceiver = finalReceiver;
            uint receivedTokenBalAfter = IERC20(output).balanceOf(address(this));
            uint received = receivedTokenBalAfter - receivedTokenBalBefore;
            deductFeeAndProceed(_path,i,output,received,_pair,type_,_finalReceiver);
            }
        }

        if(_type == SWAPTYPE.SIXTH){
            // refund dust eth, if any
            if (msg.value > amounts[0]){
                TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
            } 
        }

        ticketsGiven[_to] = false;

    }


    function deductFeeAndProceed(
        address[] memory path,
        uint i,
        address output,
        uint amount,
        address pair,
        SWAPTYPE _type,
        address finalReceiver) internal {

        if(i == (path.length - 2)){

            amount = takeBuyCharge(pair,output,amount); 
 
            if(_type == SWAPTYPE.FOURTH || _type == SWAPTYPE.FIFTH){
        
                IWBNB(WBNB).withdraw(amount);
                TransferHelper.safeTransferETH(finalReceiver, amount);
            }
            else{
                TransferHelper.safeTransfer(output, finalReceiver, amount);
            }
            if(!ticketsGiven[finalReceiver]){
                ticketsGiven[finalReceiver] = mintJackpotTickets(pair,output,finalReceiver,amount);
            }
        } 
        else{       
            amount = takeBuyCharge(pair,output,amount);
            amount = takeSellCharge(address(this),pair,output,amount); 
            address to = ExoLibrary.pairFor(factory, output, path[i + 2]);
            TransferHelper.safeTransfer(output, to, amount);   
            if(!ticketsGiven[finalReceiver]){
                ticketsGiven[finalReceiver] = mintJackpotTickets(to,output,finalReceiver,amount);
            }
        }    

    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) 
        external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = ExoLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ExoRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        _swap(SWAPTYPE.FIRST,amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline)
        external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = ExoLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'ExoRouter: EXCESSIVE_INPUT_AMOUNT');
        _swap(SWAPTYPE.SECOND,amounts, path, to);
    }

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline)
        external virtual override payable ensure(deadline) returns (uint[] memory amounts){
        require(path[0] == WBNB, 'ExoRouter: INVALID_PATH');
        amounts = ExoLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ExoRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWBNB(WBNB).deposit{value: amounts[0]}();
        _swap(SWAPTYPE.THIRD,amounts, path, to);
    }

    function swapTokensForExactETH(
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to, 
        uint deadline)
        external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WBNB, 'ExoRouter: INVALID_PATH');
        amounts = ExoLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'ExoRouter: EXCESSIVE_INPUT_AMOUNT');
        _swap(SWAPTYPE.FOURTH,amounts, path, to);
    }

    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline)
        external virtual override ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WBNB, 'ExoRouter: INVALID_PATH');
        amounts = ExoLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ExoRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        _swap(SWAPTYPE.FIFTH,amounts, path, to);
    }

    function swapETHForExactTokens(
        uint amountOut, 
        address[] calldata path, 
        address to, 
        uint deadline)
        external virtual override payable ensure(deadline) returns (uint[] memory amounts){
        require(path[0] == WBNB, 'ExoRouter: INVALID_PATH');
        amounts = ExoLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'ExoRouter: EXCESSIVE_INPUT_AMOUNT');
        IWBNB(WBNB).deposit{value: amounts[0]}();
        _swap(SWAPTYPE.SIXTH,amounts, path, to);
    }

    enum SWAPTYPE_SUPPORTFEE{
        FIRST,  //swapExactTokensForTokensSupportingFeeOnTransferTokens
        SECOND, //swapExactETHForTokensSupportingFeeOnTransferTokens 
        THIRD  //swapExactTokensForETHSupportingFeeOnTransferTokens
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(SWAPTYPE_SUPPORTFEE _type,uint amountIn,uint amountOutMin,address[] memory path, address _to) internal virtual {

        uint balanceBefore;

        address _pair = ExoLibrary.pairFor(factory, path[0], path[1]);

        if(_type == SWAPTYPE_SUPPORTFEE.FIRST ){
            
            uint amountAfterFee = takeSellCharge(msg.sender,_pair,path[0],amountIn);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, _pair, amountAfterFee
            );
            balanceBefore = IERC20(path[path.length - 1]).balanceOf(_to);
            ticketsGiven[_to] = mintJackpotTickets(_pair,path[0],_to,amountAfterFee);

        }
        else if(_type == SWAPTYPE_SUPPORTFEE.SECOND ){
            
            require(path[0] == WBNB, 'ExoRouter: INVALID_PATH');
            IWBNB(WBNB).deposit{value: amountIn}();
            uint amountAfterFee = takeSellCharge(address(this),_pair,path[0],amountIn);
            assert(IWBNB(WBNB).transfer(_pair, amountAfterFee));
            balanceBefore = IERC20(path[path.length - 1]).balanceOf(_to);
            ticketsGiven[_to] = mintJackpotTickets(_pair,path[0],_to,amountAfterFee);
        }
        else if(_type == SWAPTYPE_SUPPORTFEE.THIRD ){
            
            require(path[path.length - 1] == WBNB, 'ExoRouter: INVALID_PATH');
            uint amountAfterFee = takeSellCharge(msg.sender,_pair,path[0],amountIn);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, _pair, amountAfterFee
            );
            ticketsGiven[_to] = mintJackpotTickets(_pair,path[0],_to,amountAfterFee);

        }

        uint finalAmount;

        for (uint i; i < path.length - 1; i++) {
            address[] memory _path = path;
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = ExoLibrary.sortTokens(input, output);
            IExoPair pair = IExoPair(ExoLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = (IERC20(input).balanceOf(address(pair))) - (reserveInput); 
            amountOutput = ExoLibrary.getAmountOut(address(pair), amountInput, reserveInput, reserveOutput);
            }

            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
         
            {
                address receiver = _to;
                uint receivedTokenBalBefore = IERC20(output).balanceOf(address(this));
                pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
                uint receivedTokenBalAfter = IERC20(output).balanceOf(address(this));
                uint received = receivedTokenBalAfter - receivedTokenBalBefore;
                finalAmount = deductFeeAndProceedSupportFee(_path,i,output,received,address(pair),receiver);
            }
            
        }
            

        if(_type == SWAPTYPE_SUPPORTFEE.FIRST ||  _type == SWAPTYPE_SUPPORTFEE.SECOND){
            TransferHelper.safeTransfer(path[path.length-1], _to, finalAmount);
            require(
                ((IERC20(path[path.length - 1]).balanceOf(_to)) - (balanceBefore)) >= amountOutMin,
                'ExoRouter: INSUFFICIENT_OUTPUT_AMOUNT'
            );
        }
        else if(_type == SWAPTYPE_SUPPORTFEE.THIRD){
            uint amountOut = IERC20(WBNB).balanceOf(address(this));
            require(amountOut >= amountOutMin, 'ExoRouter: INSUFFICIENT_OUTPUT_AMOUNT');
            IWBNB(WBNB).withdraw(finalAmount);
            TransferHelper.safeTransferETH(_to, finalAmount);
        }

        ticketsGiven[_to] = false;
            
    }


    function deductFeeAndProceedSupportFee(address[] memory path,uint i,address output,uint amount,address pair,address _to) internal returns(uint){

        if(i == (path.length - 2)){

            amount = takeBuyCharge(pair,output,amount); 
            if(!ticketsGiven[_to]){
                ticketsGiven[_to] = mintJackpotTickets(pair,output,_to,amount);
            }
 
            return amount;

        } 
        else{       
            amount = takeBuyCharge(pair,output,amount);
            amount = takeSellCharge(address(this),pair,output,amount); 
            address to = ExoLibrary.pairFor(factory, output, path[i + 2]);
            TransferHelper.safeTransfer(output, to, amount); 
            if(!ticketsGiven[_to]){
                ticketsGiven[_to] = mintJackpotTickets(to,output,_to,amount);
            } 
            return amount; 
        }    

    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        _swapSupportingFeeOnTransferTokens(SWAPTYPE_SUPPORTFEE.FIRST,amountIn,amountOutMin,path, to);
    }
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        _swapSupportingFeeOnTransferTokens(SWAPTYPE_SUPPORTFEE.SECOND,msg.value,amountOutMin,path, to);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        _swapSupportingFeeOnTransferTokens(SWAPTYPE_SUPPORTFEE.THIRD,amountIn,amountOutMin,path, to);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return ExoLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(address pair, uint amountIn, uint reserveIn, uint reserveOut)
        public
        view
        virtual
        override
        returns (uint amountOut)
    {
        return ExoLibrary.getAmountOut(pair, amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(address pair,uint amountOut, uint reserveIn, uint reserveOut)
        public
        view
        virtual
        override
        returns (uint amountIn)
    {
        return ExoLibrary.getAmountIn(pair, amountOut, reserveIn, reserveOut);
    }

    function getActualAmountsOut(uint amountIn, address[] memory path)
        public 
        view  
        returns (uint[] memory amounts)
    {
        uint pathLength = path.length;
        address _pair = IExoFactory(factory).getPair(path[pathLength-2],path[pathLength-1]);
        uint buyFee = retTotalBuyFee(_pair,path[pathLength-1]);
        amounts =  ExoLibrary.getAmountsOut(factory, amountIn, path);
        amounts[pathLength-1] = ((amounts[pathLength-1]) * (uint(100e16) - buyFee)) / (uint(100e16));
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override 
        returns (uint[] memory amounts)
    {
        return ExoLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual 
        override
        returns (uint[] memory amounts)
    {
        return ExoLibrary.getAmountsIn(factory, amountOut, path);
    }
}
