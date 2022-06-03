//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IExoReferrals {

    function payReferral(address user,address token,uint256 value) external;
    
}

contract SupplementaryFee is Ownable,ReentrancyGuard {

    struct NormalFeeStruct {
        uint buyTax;        //default 1e16 = 1%
        uint sellTax;       //default 1e16 = 1%
        uint referral;      //default 0 = 0%
        address currency;   //default token0 or token1
        address destination;//default token0 or token1 fee setters
        string feeType; //fees type
    }

    struct DynamicLiquidityFeeStruct {
        uint buyTax;             //default 1e16 = 1%
        uint sellTax;            //default 1e16 = 1%
        uint referral;           //default 0 = 0%
        uint targetLpTokenSupply;//default 100e18
        address currency;        //default token0 or token1
        address destination;     //default token0 or token1 fee setters
        uint choice;             //default 0 0 = REMOVE_TAX,1=BURN TAX(normalFeeDetails[pair][token][0]),2= BOUNTY TAX ...normalFeeDetails[pair][token].length
    }

    uint public noOfPairs = 0;

    address public factory;

    address public router;

    address public exoReferrals;

    mapping(uint => address) public pair;

    mapping(address => address) public pairToken0;

    mapping(address => address) public pairToken1;

    mapping(address => mapping(address => mapping(uint => uint))) public feeBalance; //pair -> token -> TAX(BUY or SELL) -> balance

    mapping(address => mapping(address =>NormalFeeStruct[])) public normalFeeDetails; //pair -> token -> NormalFeeStruct[]

    mapping(address => mapping(address => bool)) public feeEnabled; //pair -> token -> (fee enabled or not)
    
    mapping(address => mapping(address =>DynamicLiquidityFeeStruct)) public dynamicFeeDetail;//pair -> token -> dynamicliquidityfeestruct

    string[] public feeArr = ["BURN","BOUNTY","STATIC","LOTTERY","DEVWALLET","CUSTOM1"];

    event SuppFeeReceived(address indexed pair,address indexed token,uint indexed TAX_TYPE,uint amount);

    modifier onlyFactory {
        require(msg.sender == factory,"Only Factory can call");
        _;
    }

    modifier onlyRouter {
        require(msg.sender == router,"Only Router can call");
        _;
    }

    modifier checkFeeSetter(address _pair,address token) {
        
        address tokenFeeSetter;

        if(pairToken0[_pair] == token){
            tokenFeeSetter = getToken0FeeSetter(_pair);
        }
        else if(pairToken1[_pair] == token){
            tokenFeeSetter = getToken1FeeSetter(_pair);
        }

        require((tokenFeeSetter == msg.sender),"CALLER IS NOT FEE SETTER OF THIS TOKEN");
        _;
    }

    constructor() {}

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

    function setExoReferrals(address _exoReferrals) external {
        if(exoReferrals == address(0)){
            exoReferrals = _exoReferrals;
        }
        else{
            setExoReferralsInternal(_exoReferrals);
        }
    }

    function setExoReferralsInternal(address _exoReferrals) internal onlyOwner {
        exoReferrals = _exoReferrals;
    }

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

    function toggleFeeEnabled(address _pair,address _token) external checkFeeSetter(_pair,_token){
        feeEnabled[_pair][_token] = !feeEnabled[_pair][_token];
    }

    function increment(address user,address _pair,address token,uint tax,uint amount) external onlyRouter {
        
        uint referralAmount;
        
        if(tax == 1)
        referralAmount= (retTotalReferralFee(_pair,token) * amount) / (retTotalBuyFee(_pair,token)); //(5e16 or 5%) * (3000) / (100e16 or 100%)
        else if(tax == 2)
        referralAmount= (retTotalReferralFee(_pair,token) * amount) / (retTotalSellFee(_pair,token)); //(5e16 or 5%) * (3000) / (100e16 or 100%)

        if(referralAmount > 0){
            TransferHelper.safeTransfer(token,exoReferrals,referralAmount);
            IExoReferrals(exoReferrals).payReferral(user,token,referralAmount);
        }
        feeBalance[_pair][token][tax] += (amount - referralAmount);
        emit SuppFeeReceived(_pair,token,tax,(amount));
    }

    function normalFeeDetailsLength(address _pair, address _token) public view returns(uint) {
        return normalFeeDetails[_pair][_token].length;
    }

    function getAllNormalFees(address _pair, address _token) public view returns(NormalFeeStruct[] memory){
        uint length  = normalFeeDetails[_pair][_token].length;
        NormalFeeStruct [] memory normal = new NormalFeeStruct[](length);
        for(uint i=0; i<length; i++){
           normal[i] = normalFeeDetails[_pair][_token][i];
        }
        return normal;
    }

    function addAnotherTax(address _pair,address token,NormalFeeStruct memory normal) external checkFeeSetter(_pair,token) {
        require(normal.currency == token,"currency is not valid");
        NormalFeeStruct[] storage n = normalFeeDetails[_pair][token];
        n.push(normal);
    }

    function changeNormalFeeParams(
        address _pair,
        address token,
        uint feeType,
        NormalFeeStruct memory newNormal) external checkFeeSetter(_pair,token) {

            require(feeType < (normalFeeDetails[_pair][token]).length,"This Fee Type not exists");
            NormalFeeStruct storage prevNormal = normalFeeDetails[_pair][token][feeType];
            prevNormal.buyTax = newNormal.buyTax;
            prevNormal.sellTax = newNormal.sellTax;
            prevNormal.referral = newNormal.referral;
            prevNormal.destination = newNormal.destination;

            require(retTotalBuyFee(_pair,token) <= 100e16,"total buy fee cannot exceed 100 percent");
            require(retTotalSellFee(_pair,token) <= 100e16,"total sell fee cannot exceed 100 percent");
        }

    function changeDynamicFeeParams(
        address _pair,
        address token,
        DynamicLiquidityFeeStruct memory newDynamic) external checkFeeSetter(_pair,token) {

            require(newDynamic.choice <= normalFeeDetails[_pair][token].length,"New Dynamic Choice Selection Not Exists");

            DynamicLiquidityFeeStruct storage prevDynamic = dynamicFeeDetail[_pair][token];
            prevDynamic.buyTax = newDynamic.buyTax;
            prevDynamic.sellTax = newDynamic.sellTax;
            prevDynamic.referral = newDynamic.referral;
            prevDynamic.destination = newDynamic.destination;
            prevDynamic.targetLpTokenSupply = newDynamic.targetLpTokenSupply;
            prevDynamic.choice = 1;

            require(retTotalBuyFee(_pair,token) <= 100e16,"total buy fee cannot exceed 100 percent");
            require(retTotalSellFee(_pair,token) <= 100e16,"total sell fee cannot exceed 100 percent");

            prevDynamic.choice = newDynamic.choice;



        }

    function initialize(address _pair) external onlyFactory{

        address token0 = IExoPair(_pair).token0();
        address token1 = IExoPair(_pair).token1();
        pairToken0[_pair] = token0;
        pairToken1[_pair] = token1;
        pair[noOfPairs++] = _pair;

        DynamicLiquidityFeeStruct storage dynamicFeeStruc1  = dynamicFeeDetail[_pair][token0];
        dynamicFeeStruc1.buyTax = 1e16;
        dynamicFeeStruc1.sellTax = 1e16;
        dynamicFeeStruc1.referral = 0;
        dynamicFeeStruc1.targetLpTokenSupply = 100e18;
        dynamicFeeStruc1.currency = token0;
        dynamicFeeStruc1.destination = getToken0FeeSetter(_pair);

        DynamicLiquidityFeeStruct storage dynamicFeeStruc2  = dynamicFeeDetail[_pair][token1];
        dynamicFeeStruc2.buyTax = 1e16;
        dynamicFeeStruc2.sellTax = 1e16;
        dynamicFeeStruc2.referral = 0;
        dynamicFeeStruc2.targetLpTokenSupply = 100e18;
        dynamicFeeStruc2.currency = token1;
        dynamicFeeStruc2.destination = getToken1FeeSetter(_pair);
        
        for(uint i = 0 ; i < 6 ; i++){
            NormalFeeStruct memory feeStruc;
            feeStruc.buyTax = 1e16;
            feeStruc.sellTax = 1e16;
            feeStruc.referral = 0;
            feeStruc.currency = token0;
            feeStruc.destination = getToken0FeeSetter(_pair);
            feeStruc.feeType = feeArr[i];
            (normalFeeDetails[_pair][token0]).push(feeStruc);

        }

        for(uint i = 0 ; i < 6 ; i++){
            NormalFeeStruct memory feeStruc;
            feeStruc.buyTax = 1e16;
            feeStruc.sellTax = 1e16;
            feeStruc.referral = 0;
            feeStruc.currency = token1;
            feeStruc.destination = getToken1FeeSetter(_pair);
            feeStruc.feeType = feeArr[i];
            (normalFeeDetails[_pair][token1]).push(feeStruc);
        }
        feeEnabled[_pair][token0] = true;
        feeEnabled[_pair][token1] = true;

    }

   /*
    * When withdawing fees from this contract
    * DYNAMIC LIQUIDITY TAX will be on index 0
    * BURN TAX will be on index 1
    * BOUNTY TAX will be on index 2
    * STATIC LIQUIDTY TAX will be on index 3
    * LOTTERY TAX will be on index 4
    * DEV WALLET TAX will be on index 5
    * CUSTOM TAX will be on index 6
    */
    function withdraw(address _pair,address token,uint amount,uint tax) external nonReentrant checkFeeSetter(_pair,token) {

        require((tax == 0 || tax == 1),"WRONG TAX TYPE");
        
        require(feeBalance[_pair][token][tax] >= amount,"INSUFFICIENT FEE BALANCE");

        feeBalance[_pair][token][tax] -= amount;

        DynamicLiquidityFeeStruct memory dynamicDetail = dynamicFeeDetail[_pair][token];

        NormalFeeStruct[] memory normalDetails = normalFeeDetails[_pair][token]; 

        uint[] memory taxAmounts = new uint[](normalDetails.length + 1);

        if(tax == 1){
            
            //BUY TAX
            
            uint totalBuyTax = retTotalBuyFee(_pair,token);

            uint feePercentage = dynamicDetail.buyTax;
            
            if(IExoPair(_pair).totalSupply() < dynamicDetail.targetLpTokenSupply){
                taxAmounts[0] = (amount * feePercentage) / totalBuyTax; //send dynamic liquidity fee to destination address
            }
            else{
                if(dynamicDetail.choice != 0)
                taxAmounts[dynamicDetail.choice] = (amount * feePercentage) / totalBuyTax;  //send dynamic liquidity fee to new selected criteria
            }

            for(uint i = 0 ; i < taxAmounts.length - 1 ; i++){
                NormalFeeStruct memory feeStruc  = normalDetails[i];
                feePercentage = feeStruc.buyTax;
                taxAmounts[i+1] += (amount * feePercentage) / totalBuyTax; 
            }
        }
        else{
            
            //SELL TAX
            
            uint totalSellTax = retTotalSellFee(_pair,token);

            uint feePercentage = dynamicDetail.sellTax;
            
            if(IExoPair(_pair).totalSupply() < dynamicDetail.targetLpTokenSupply){
                taxAmounts[0] = (amount * feePercentage) / totalSellTax; //send dynamic liquidity fee to destination address
            }
            else{
                if(dynamicDetail.choice != 0)
                taxAmounts[dynamicDetail.choice] = (amount * feePercentage) / totalSellTax;  //send dynamic liquidity fee to new selected criteria
            }

            for(uint i = 0 ; i < taxAmounts.length - 1 ; i++){
                NormalFeeStruct memory feeStruc  = normalDetails[i];
                feePercentage = feeStruc.sellTax;
                taxAmounts[i+1] += (amount * feePercentage) / totalSellTax; 
            }
        }
        
        for(uint i = 0 ; i < taxAmounts.length ; i++){
            if(taxAmounts[i] != 0){
                address destination = (i == 0) ? dynamicDetail.destination : (normalDetails[i-1]).destination;
                TransferHelper.safeTransfer(token,destination,taxAmounts[i]);
            }
        }
    }


    function getToken0FeeSetter(address _pair) public view returns(address){
        return IExoPair(_pair).feeSetter1();
    }

    function getToken1FeeSetter(address _pair) public view returns(address){
        return IExoPair(_pair).feeSetter2();
    }

    function retTotalSellFee(address _pair,address token) public view returns(uint total) {

        if(!feeEnabled[_pair][token]){
            return 0;
        }
        
        NormalFeeStruct[] memory arr = normalFeeDetails[_pair][token];
        
        DynamicLiquidityFeeStruct memory d = dynamicFeeDetail[_pair][token];

        for(uint i = 0 ; i < arr.length ; i++){
            total += arr[i].sellTax;
        }

        if(IExoPair(_pair).totalSupply() < d.targetLpTokenSupply){
            total += d.sellTax;
        }
        else{
            if(d.choice != 0)
            total += d.sellTax;
    
        }

        total += retTotalReferralFee(_pair,token);

    }

    function retTotalBuyFee(address _pair,address token) public view returns(uint total) {

        if(!feeEnabled[_pair][token]){
            return 0;
        }

        NormalFeeStruct[] memory arr = normalFeeDetails[_pair][token];
        
        DynamicLiquidityFeeStruct memory d = dynamicFeeDetail[_pair][token];

        for(uint i = 0 ; i < arr.length ; i++){
            total += arr[i].buyTax;
        }

        if(IExoPair(_pair).totalSupply() < d.targetLpTokenSupply){
            total += d.buyTax;
        }
        else{
            if(d.choice != 0)
            total += d.buyTax;
    
        }

        total += retTotalReferralFee(_pair,token);
        
    }

    function retTotalReferralFee(address _pair,address token) public view returns(uint total) {

        if(!feeEnabled[_pair][token]){
            return 0;
        }

        NormalFeeStruct[] memory arr = normalFeeDetails[_pair][token];
        
        DynamicLiquidityFeeStruct memory d = dynamicFeeDetail[_pair][token];

        for(uint i = 0 ; i < arr.length ; i++){
            total += arr[i].referral;
        }

        if(IExoPair(_pair).totalSupply() < d.targetLpTokenSupply){
            total += d.referral;
        }
        else{
            if(d.choice != 0)
            total += d.referral;
    
        }
        
    }
}
