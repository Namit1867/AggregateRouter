//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";

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

interface IExoPair{
    function token0() external view returns(address);
    function token1() external view returns(address);
    function treasuryAddress() external view returns(address);
    function buyBackAddress() external view returns(address);
    function jackPotAddress() external view returns(address);
    function dev1Address() external view returns(address);
    function dev2Address() external view returns(address);
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
}

contract BaseFeeVault is Ownable {


    //0 --> TREASURY
    //1 --> JACKPOT
    //2 --> BUYBACK
    //3 --> DEV1
    //4 --> DEV2
    

    address public factory;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    mapping (address => bool) public whiteListedPairs;

    mapping(address => mapping(address => mapping(uint => uint))) public pairBaseFee; // pairBaseFee[EXO-BUSD][EXO][0..4] = total fees
 
    constructor() {}

    event BaseFeeReceive(address indexed pair,address indexed token0,address indexed token1,uint amount0,uint amount1);

    function setFactory(address _factory) external {
        if(factory == address(0)){
            factory = _factory;
        }
        else{
            setFactoryInternal(_factory);
        }
    }

    function setFactoryInternal(address _factory) internal onlyOwner {
        factory = _factory;
    }

    function toggleWhiteListed(address pair) external {
        require(_msgSender() == factory,"Only factory can whitelist pairs");
        whiteListedPairs[pair] = true;
    }

    function depositBaseFees(address pair,address token0,address token1,uint[] memory tokenAmounts) external {

        require(whiteListedPairs[msg.sender],"calling contract must be a whitelisted pair");

        uint token0Amounts;
        uint token1Amounts;
            
        for(uint i = 0 ; i < 10 ; i++){
            address token = (i < 5) ? token0 : token1;
            uint val = (i < 5) ? i : (i - 5);
            pairBaseFee[pair][token][val] += tokenAmounts[i];
            
            if(i<5)
            token0Amounts += tokenAmounts[i];
            else
            token1Amounts += tokenAmounts[i];
        }

        console.log(token0Amounts,token1Amounts);

        emit BaseFeeReceive(pair,token0,token1,token0Amounts,token1Amounts);
    }

    function getAddress(address pair,uint i) internal view returns(address){
        if(i == 0)
        return IExoPair(pair).treasuryAddress();
        if(i == 1)
        return IExoPair(pair).jackPotAddress();
        if(i == 2)
        return IExoPair(pair).buyBackAddress();
        if(i == 3)
        return IExoPair(pair).dev1Address();
        if(i == 4)
        return IExoPair(pair).dev2Address();
        
        return address(0);
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Exo: TRANSFER_FAILED');
    }

    function withdrawBaseFees(address pair) external onlyOwner{

        address token0 = IExoPair(pair).token0();
        address token1 = IExoPair(pair).token1();

        for(uint i = 0 ; i < 10 ; i++){
            address token = (i < 5) ? token0 : token1;
            uint val = (i < 5) ? i : (i - 5);
            uint amount = pairBaseFee[pair][token][val];
            if(amount > 0){
                address receiver = getAddress(pair,val);
                _safeTransfer(token, receiver, amount);
                pairBaseFee[pair][token][val] = 0;
            }
        }
    }
}