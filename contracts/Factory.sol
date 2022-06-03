//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IToken{
    function owner() external view returns(address);
    function deployer() external view returns(address);
}


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

    function initialize(address, address, address, address, address, address) external;
}

contract ExoERC20 {

    string public constant name = 'Exo LPs';
    string public constant symbol = 'Exo-LP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'Exo: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Exo: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// a library for performing various math operations
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
// range: [0, 2**112 - 1]
// resolution: 1 / 2**112
library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
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

interface IExoCallee {
    function exoCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IBaseFeeVault {
    function setFactory(address _factory) external;
    function toggleWhiteListed(address pair) external;
    function depositBaseFees(
        address pair,
        address token0,
        address token1,
        uint[] memory tokenAmounts
    ) external;
}


contract ExoPair is ExoERC20 {
    
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;
    address public WBNB;

    uint256 public constant maxBaseFeePercentage = 5000; //0.5% and fee factor ranges (0.0001% to 0.5000%)

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint256 public treasuryFeeFactor;
    uint256 public buyBackFeeFactor;
    uint256 public jackPotFeeFactor;
    uint256 public devFeeFactor1;
    uint256 public devFeeFactor2;
    uint256 public lpFeeFactor;

    uint256 public nFactor;
    uint256 public dFactor;

    address public treasuryAddress;
    address public buyBackAddress;
    address public jackPotAddress;
    address public dev1Address;
    address public dev2Address;
    address public feeSetter1;
    address public feeSetter2;
    address public baseFeeVault;


    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Exo: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Exo: TRANSFER_FAILED');
    }

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

    modifier onlyFactory {
        require(msg.sender == factory,"Only Factory can call");
        _;
    }

    modifier checkZeroAddress(address _address) {
        require(_address != address(0), "Invalid Address");
        _;
    }

    constructor() {
        factory = msg.sender;
        treasuryFeeFactor = 500;//0.05% 
        jackPotFeeFactor = 500;//0.05% 
        buyBackFeeFactor = 500;//0.05% 
        lpFeeFactor = 500;//0.05% 
        setFeeFraction();
    }

    function tryToFind(address token) internal view returns(address owner){
        try IToken(token).owner() returns(address temp){
            owner = temp;
        } catch {
            try IToken(token).deployer() returns(address temp){
                owner = temp;
            }
            catch {

            }
        }
    }

    function initializeFeeToSetter1(address _token0) internal {

        if(_token0 != WBNB){
            
            address out = tryToFind(_token0);
            
            if(out != address(0)){
                feeSetter1 = out;
                dev1Address = out;
                devFeeFactor1 = 250;//0.025%
            }

        }
        
    } 

    function initializeFeeToSetter2(address _token1) internal {
        
        if(_token1 != WBNB){
            
            address out = tryToFind(_token1);
            
            if(out != address(0)){
                feeSetter2 = out;
                dev2Address = out;
                devFeeFactor2 = 250;//0.025%
            }

        }
    } 


    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, address owner,address _buyBack,address _WBNB,address _baseFeeVault) external onlyFactory{
        WBNB = _WBNB;
        token0 = _token0;
        token1 = _token1;
        treasuryAddress = owner;
        jackPotAddress  = owner;
        buyBackAddress  = _buyBack;
        baseFeeVault = _baseFeeVault;
        initializeFeeToSetter1(_token0);
        initializeFeeToSetter2(_token1);
    }

    function getTreasuryFeeFactor() external view returns(uint){
        bool enable = ExoFactory(factory).isPegEnable();
        return enable ? treasuryFeeFactor / 2 : treasuryFeeFactor ;
    }

    function getJackpotFeeFactor() external view returns(uint){
        bool enable = ExoFactory(factory).isPegEnable();
        return enable ? jackPotFeeFactor / 2 : jackPotFeeFactor ;
    }

    function getBuybackFeeFactor() external view returns(uint){
       bool enable = ExoFactory(factory).isPegEnable();
       return enable ? (getTotalFees() + buyBackFeeFactor) / (2) : buyBackFeeFactor ;
    }

    function getDev1FeeFactor() external view returns(uint){
       bool enable = ExoFactory(factory).isPegEnable();
       return enable ? devFeeFactor1 / 2 : devFeeFactor1 ;
    }

    function getDev2FeeFactor() external view returns(uint){
       bool enable = ExoFactory(factory).isPegEnable();
       return enable ? devFeeFactor2 / 2 : devFeeFactor2 ;
    }

    function getLpFeeFactor() external view returns(uint){
       bool enable = ExoFactory(factory).isPegEnable();
       return enable ? lpFeeFactor / 2 : lpFeeFactor;
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyFactory checkZeroAddress(_treasuryAddress){
        treasuryAddress = _treasuryAddress;
    }

    function setJackpotAddress(address _jackpotAddress) external onlyFactory checkZeroAddress(_jackpotAddress){
        jackPotAddress = _jackpotAddress;
    }

    function setBuybackAddress(address _buybackAddress) external onlyFactory checkZeroAddress(_buybackAddress){
        buyBackAddress = _buybackAddress;
    }

    function setDev1Address(address _dev1Address) external onlyFactory checkZeroAddress(_dev1Address){
        dev1Address = _dev1Address;
    }

    function setDev2Address(address _dev2Address) external onlyFactory checkZeroAddress(_dev2Address){
        dev2Address = _dev2Address;
    }

    function setFeeSetter1(address _newFeeSetter1) external onlyFactory checkZeroAddress(_newFeeSetter1){
        feeSetter1 = _newFeeSetter1;
    }

    function setFeeSetter2(address _newFeeSetter2) external onlyFactory checkZeroAddress(_newFeeSetter2){
        feeSetter2 = _newFeeSetter2;
    }

    function getTotalFees() public view returns(uint256) {
        uint256 _totalFees = treasuryFeeFactor
        + buyBackFeeFactor
        + jackPotFeeFactor
        + devFeeFactor1
        + devFeeFactor2
        + lpFeeFactor;
        return _totalFees;
    }

    function checkNewFeeFactor(uint oldFeeFactor,uint newFeeFactor) public view returns(bool success){
        if(newFeeFactor >= 0 && newFeeFactor <= maxBaseFeePercentage){
            uint256 oldTotalWithoutGivenFeeFactor = getTotalFees() - oldFeeFactor; // total fee without given factor
            uint256 newTotalWithGivenFeeFactor = oldTotalWithoutGivenFeeFactor + newFeeFactor;
            success = (newTotalWithGivenFeeFactor <= maxBaseFeePercentage) ? true : false;
        }
    }

    function setTreasuryFee(uint256 _treasuryFeeFactor) external onlyFactory{
        require(checkNewFeeFactor(treasuryFeeFactor,_treasuryFeeFactor) , "Wrong New Fee Factor");
        treasuryFeeFactor = _treasuryFeeFactor;
        setFeeFraction();
    }

    function setBuybackFee(uint256 _buyBackFeeFactor) external onlyFactory{
        require(checkNewFeeFactor(buyBackFeeFactor,_buyBackFeeFactor) , "Wrong New Fee Factor");
        buyBackFeeFactor = _buyBackFeeFactor;
        setFeeFraction();
    }

    function setJackpotFee(uint256 _jackPotFeeFactor) external onlyFactory{
        require(checkNewFeeFactor(jackPotFeeFactor,_jackPotFeeFactor) , "Wrong New Fee Factor");
        jackPotFeeFactor = _jackPotFeeFactor;
        setFeeFraction();
    }

    function setDevFee1(uint256 _devFeeFactor1) external onlyFactory{
        require(checkNewFeeFactor(devFeeFactor1,_devFeeFactor1) , "Wrong New Fee Factor");
        require(dev1Address != address(0),"dev1Address is zero");
        devFeeFactor1 = _devFeeFactor1;
        setFeeFraction();
    }

    function setDevFee2(uint256 _devFeeFactor2) external onlyFactory{
        require(checkNewFeeFactor(devFeeFactor2,_devFeeFactor2) , "Wrong New Fee Factor");
        require(dev2Address != address(0),"dev2Address is zero");
        devFeeFactor2 = _devFeeFactor2;
        setFeeFraction();
    }

    function setLpFee(uint256 _lpFeeFactor) external onlyFactory{
        require(checkNewFeeFactor(lpFeeFactor,_lpFeeFactor) , "Wrong New Fee Factor");
        lpFeeFactor = _lpFeeFactor;
        setFeeFraction();
    }

    function setFeeFraction() internal {
        uint256 totalFees = getTotalFees();
        uint256 lpFees = lpFeeFactor;
        (nFactor,dFactor) = gcd((totalFees - lpFees),totalFees);
        dFactor = dFactor - nFactor;
    }

    function gcd(uint256 a, uint256 b) 
        internal pure
        returns (uint256,uint256)
    {
        uint256 _a = a;
        uint256 _b = b;
        uint256 temp;
        while (_b > 0) {
            temp = _b;
            _b = _a % _b;
            _a = temp;
        }
        return ((a / _a) ,( b /_a));
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'Exo: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    function _mintBaseFee(uint totalLiquidity,uint additionalLiquidity,bool flag) internal {
        bool enable = ExoFactory(factory).isPegEnable();
        uint256 totalFees = getTotalFees();

        uint _totalLiquidity = totalLiquidity;
        uint _treasury = (enable ? treasuryFeeFactor / 2 : treasuryFeeFactor);
        uint _jackpot  = (enable ? jackPotFeeFactor / 2 : jackPotFeeFactor);
        uint _buyback  = (enable ? (getTotalFees() + buyBackFeeFactor) / (2) : buyBackFeeFactor);
        uint _dev1     = (enable ? devFeeFactor1 / 2 : devFeeFactor1);
        uint _dev2 = (enable ? devFeeFactor2 / 2 : devFeeFactor2);

        totalFees = totalFees - lpFeeFactor;



        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        if(!flag){
            //Burn
            uint a;
            uint b;

            a = (additionalLiquidity * balance0) / (totalSupply);
            b = (additionalLiquidity * balance1) / (totalSupply);

            balance0 = balance0 - a;
            balance1 = balance1 - b;
            
        }

        //in Add Liquidity
        //_totalLiquidity = LPs to be minted to useradding the liquidity
        //_totalSupply = (previous total supply) + (LPs to be minted to useradding the liquidity) + (fees to be minted in terms of LP)
        //balance0 = previous reserve0 + amount of token0 provided for adding liquidity
        //balance1 = previous reserve1 + amount of token1 provided for adding liquidity
        uint _totalSupply = flag ? 
        (totalSupply + _totalLiquidity + additionalLiquidity): 
        (totalSupply + _totalLiquidity - additionalLiquidity); 

        uint token0Amount = (_totalLiquidity * balance0) / (_totalSupply);
        uint token1Amount = (_totalLiquidity * balance1) / (_totalSupply);

        uint[] memory tokenAmounts = new uint[](10);

        for(uint i = 0 ; i < 10 ; i += 5){
            uint amount = (i == 0) ? token0Amount : token1Amount;
            tokenAmounts[i]   = (amount * _treasury) / (totalFees);
            tokenAmounts[i+1] = (amount * _jackpot) / (totalFees);
            tokenAmounts[i+2] = (amount * _buyback) / (totalFees);
            tokenAmounts[i+3] = (amount * _dev1) / (totalFees);
            tokenAmounts[i+4] = (amount * _dev2) / (totalFees);
        }
        _safeTransfer(token0, baseFeeVault, token0Amount);
        _safeTransfer(token1, baseFeeVault, token1Amount);

        IBaseFeeVault(baseFeeVault).depositBaseFees(address(this),token0,token1,tokenAmounts);
    
    }

    function _getFeeOn() private view returns(bool _feeOn){
        _feeOn = treasuryAddress != address(0);
        _feeOn = jackPotAddress != address(0);
        _feeOn = buyBackAddress != address(0);
        return _feeOn;
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1,uint _additionalLiquidity,bool flag) private returns (bool feeOn) {
        feeOn = _getFeeOn();
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0) * (_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply * (rootK - rootKLast) * (nFactor);
                    uint denominator = (rootK * dFactor) + (rootKLast * nFactor);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) {
                        _mintBaseFee(liquidity,_additionalLiquidity,flag);
                    }      
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min( (amount0 *_totalSupply) / _reserve0 , (amount1 * _totalSupply) / _reserve1);
        } 
        bool feeOn = _mintFee(_reserve0, _reserve1,liquidity,true);
        require(liquidity > 0, 'Exo: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * (reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1,liquidity,false);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (liquidity * balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (liquidity * balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Exo: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * (reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'Exo: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Exo: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'Exo: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IExoCallee(to).exoCall(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'Exo: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint totalFees = getTotalFees();
        uint balance0Adjusted = (balance0 * 1000000) - (amount0In * totalFees);
        uint balance1Adjusted = (balance1 * 1000000) - (amount1In * totalFees);
        require( (balance0Adjusted * balance1Adjusted) >= uint(_reserve0) * (_reserve1) * (1000000**2), 'Exo: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, (IERC20(_token0).balanceOf(address(this))) - (reserve0));
        _safeTransfer(_token1, to, (IERC20(_token1).balanceOf(address(this))) - (reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface AggregatorValidatorInterface {
    
    function latestAnswer() external view returns(int256);

    function latestRoundData() external view returns(uint80, int256, uint256, uint256, uint80);
    
}


interface ISupplementaryFee {
    function setRouter(address _router) external;
    function setFactory(address _factory) external;
    function initialize(address _pair) external;
}

interface IExoPrice {
    function getPrice(address token) external view returns(uint);
    function update() external;
}


contract ExoFactory is Ownable {
    
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(ExoPair).creationCode));

    mapping(address => mapping(address => address)) public getPair;

    uint public exoPeggedPrice;

    enum PriceType {
        RESERVES,
        CHAINLINK,
        TWAP
    }

    PriceType public exoPriceType;

    address[] public allPairs;

    address public immutable exoAddress;

    address public immutable busdAddress;

    address public immutable WBNB;

    address public exoBusdPair;

    address public suppFeeContract;

    address public buyBackContract;

    address public exoPriceContract;

    address public chainLinkExoOracle; //set this if exo price is availaible on chainlink(EXO/USD price feed)

    address public chainLinkBusdOracle;

    address public baseFeeVault;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    modifier onlyFeeSetter1(address _pair){
        require(msg.sender == IExoPair(_pair).feeSetter1(),"Only Fee Setter 1 can call this function");
        _;
    }

    modifier onlyFeeSetter2(address _pair){
        require(msg.sender == IExoPair(_pair).feeSetter2(),"Only Fee Setter 2 can call this function");
        _;
    }

    constructor(address _exoAddress,address _busdAddress,address _suppFeeContract,address _buyBackContract,address _WBNB,address _baseFeeVault,address _chainLinkBusdOracle) {
        WBNB = _WBNB;
        exoAddress = _exoAddress;
        busdAddress  = _busdAddress;
        suppFeeContract = _suppFeeContract;
        buyBackContract = _buyBackContract;
        baseFeeVault = _baseFeeVault;
        chainLinkBusdOracle = _chainLinkBusdOracle;
        IBaseFeeVault(baseFeeVault).setFactory(address(this));
        ISupplementaryFee(_suppFeeContract).setFactory(address(this));
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function changExoPriceType(PriceType _type) external onlyOwner {
        exoPriceType = _type;
    }

    function setExoChainLink(address _exoChainLink) external onlyOwner {
        chainLinkExoOracle = _exoChainLink;
        exoPriceType = PriceType.CHAINLINK;
    }

    function setExoPriceContract(address _exoPriceContract) external onlyOwner {
        exoPriceContract = _exoPriceContract;
        exoPriceType = PriceType.TWAP;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Exo: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Exo: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Exo: PAIR_EXISTS'); // single check is sufficient
        
        bytes memory bytecode = type(ExoPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IBaseFeeVault(baseFeeVault).toggleWhiteListed(pair);
        IExoPair(pair).initialize(token0, token1,owner(),buyBackContract,WBNB,baseFeeVault);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        ISupplementaryFee(suppFeeContract).initialize(pair); 
        
        if(((tokenA == exoAddress) || (tokenA == busdAddress)) && 
        ((tokenB == busdAddress) || (tokenB == exoAddress))){
            exoBusdPair = pair;
            exoPeggedPrice = 0; // 0$
        }
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFees(address _pair,
    uint256 _treasuryFeeFactor,
    uint256 _jackPotFeeFactor,
    uint256 _buyBackFeeFactor,
    uint256 _devFeeFactor1,
    uint256 _devFeeFactor2,
    uint256 _lpFeeFactor) external onlyOwner {
    
        ExoPair(_pair).setTreasuryFee(_treasuryFeeFactor);
        ExoPair(_pair).setJackpotFee(_jackPotFeeFactor);
        ExoPair(_pair).setBuybackFee(_buyBackFeeFactor);
        ExoPair(_pair).setDevFee1(_devFeeFactor1);
        ExoPair(_pair).setDevFee2(_devFeeFactor2);
        ExoPair(_pair).setLpFee(_lpFeeFactor);

    }

    function setTreasuryFeeFactor(address _pair, uint256 _newFeeFactor) external onlyOwner {
        ExoPair(_pair).setTreasuryFee(_newFeeFactor);
    }

    function setJackpotFeeFactor(address _pair, uint256 _newFeeFactor) external onlyOwner {
        ExoPair(_pair).setJackpotFee(_newFeeFactor);
    }

    function setBuybackFeeFactor(address _pair, uint256 _newFeeFactor) external onlyOwner {
        ExoPair(_pair).setBuybackFee(_newFeeFactor);
    }

    function setDev1FeeFactor(address _pair, uint256 _newFeeFactor) external onlyOwner {
        ExoPair(_pair).setDevFee1(_newFeeFactor);
    }

    function setDev2FeeFactor(address _pair, uint256 _newFeeFactor) external onlyOwner {
        ExoPair(_pair).setDevFee2(_newFeeFactor);
    }

    function setLpFeeFactor(address _pair, uint256 _newFeeFactor) external onlyOwner {
        ExoPair(_pair).setLpFee(_newFeeFactor);
    }

    function setFeeAddresses(address _pair, 
    address _treasuryAddress, 
    address _jackpotAddress, 
    address _buybackAddress) external onlyOwner {
        require(_pair != address(0), 'Exo: Pair is invalid');
        
        ExoPair(_pair).setTreasuryAddress(_treasuryAddress);
        ExoPair(_pair).setJackpotAddress(_jackpotAddress);
        ExoPair(_pair).setBuybackAddress(_buybackAddress);
    }

    function setFeeSetter1(address _pair, address _newFeeSetter1) external onlyFeeSetter1(_pair) {
        require(_pair != address(0) && _newFeeSetter1 != address(0),"Arguments cannot be zero address");
        IExoPair(_pair).setFeeSetter1(_newFeeSetter1);
    }

    function setFeeSetter2(address _pair, address _newFeeSetter2) external onlyFeeSetter2(_pair) {
        require(_pair != address(0) && _newFeeSetter2 != address(0),"Arguments cannot be zero address");
        IExoPair(_pair).setFeeSetter2(_newFeeSetter2);
    }

    function setDev1Address(address _pair, address _devWallet1) external onlyFeeSetter1(_pair){
        ExoPair(_pair).setDev1Address(_devWallet1);
    }

    function setDev2Address(address _pair, address _devWallet2) external onlyFeeSetter2(_pair){
        ExoPair(_pair).setDev2Address(_devWallet2);
    }

    function setTreasuryAddress(address _pair, address _treasuryAddress) external onlyOwner {
        ExoPair(_pair).setTreasuryAddress(_treasuryAddress);
    }

    function setJackpotAddress(address _pair, address _jackpotAddress) external onlyOwner {
        ExoPair(_pair).setJackpotAddress(_jackpotAddress);
    }

    function setBuybackAddress(address _pair, address _buybackAddress) external onlyOwner {
        ExoPair(_pair).setBuybackAddress(_buybackAddress);
    }

    function setExoPeggedPrice(uint newPeggedPrice) external onlyOwner {
        exoPeggedPrice = newPeggedPrice;
    }

    function isPegEnable() external view returns(bool) {
        uint exoUsdPrice = getExoPrice();
        return (exoUsdPrice >= exoPeggedPrice) ? false : true ;

    } 

    function reservePrice() internal view returns(uint) {

        (uint256 _reserve0,uint256 _reserve1,) = (exoBusdPair != address(0)) ?
        IExoPair(exoBusdPair).getReserves() : (0,0,0);

        if(_reserve0 > 0 && _reserve1 > 0) {
            
            uint busdPerExo;
            address token0 = IExoPair(exoBusdPair).token0();
            busdPerExo = (token0 == busdAddress) ? 
            (_reserve0 * 1e18) / (_reserve1) : 
            (_reserve1 * 1e18) / (_reserve0);

            (,int256 latestPrice,,,) = AggregatorValidatorInterface(chainLinkBusdOracle).latestRoundData();
            uint256 busdPrice = uint256(latestPrice); // in 8 decimals

            uint exoUsdPrice = (busdPerExo * busdPrice) / (1e8);
            return exoUsdPrice;

        }
        return 0; 

    }

    function getExoPrice() public view returns(uint){
        //reserve0 / reserve1 means amount of token0 per token1 
        if(exoPriceType == PriceType.RESERVES){
            //Reserves Price for EXO
            return reservePrice();
        }
        else if(exoPriceType == PriceType.CHAINLINK){
            //chainlink for exo token
            (,int256 latestPrice,,,) = AggregatorValidatorInterface(chainLinkExoOracle).latestRoundData();
            uint256 exoPrice = uint256(latestPrice); // in 8 decimals
            exoPrice = (exoPrice * 1e18) / (1e8);
            return exoPrice;
        }
        else{
            //TWAP price for EXO
            if(exoPriceContract != address(0)) {
                uint busdPerExo = IExoPrice(exoPriceContract).getPrice(exoAddress);
                (,int256 latestPrice,,,) = AggregatorValidatorInterface(chainLinkBusdOracle).latestRoundData();
                uint256 busdPrice = uint256(latestPrice); // in 8 decimals
                uint exoUsdPrice = (busdPerExo * busdPrice) / (1e8);
                return exoUsdPrice;
            }     
            return 0; 
        }
        

    }
}
