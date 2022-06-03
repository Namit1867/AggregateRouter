//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ExoReferral is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    using SafeERC20 for IERC20;

    address public exoTreasury;

    ///
    ///@dev The struct of account information
    ///@param referrerNftId Referral NFT ID
    ///@param reward The total referral reward of an address
    ///@param usingReferralReward The total referral reward of this account for using parent user referral
    ///@param referredCount The total referral amount of an address
    ///@param lastActiveTimestamp The last active timestamp of an address
    ///
    struct Account {
        bool hasReferral; //because for NFT id 0 we cannot check so making a bool to check whether this user is using a referral or not
        uint256 referrerNftId;
        uint256 reward;
        uint256 usingReferralReward;
        uint256 referredCount;
        uint256 lastActiveTimestamp;
    }

    ///
    ///@dev The struct of Referral Arguments
    ///@param referrerRate Referrer level rate.
    ///@param referreRate Referre level rate.
    ///@param lowerBound[] lower bounds of no. of refferers for bonus.
    ///@param rate[] rate of bonus to refferers according to lower bounds.
    ///
    struct ReferralArgs {
        uint256 referrerRate;
        uint256 referreRate;
        uint256[] lowerBound;
        uint256[] rate;
    }

    event RegisteredReferer(address referee, uint256 referralId);
    event RegisteredRefererFailed(
        address referee,
        uint256 referralId,
        string reason
    );
    event PaidReferral(
        address from,
        address to,
        uint256 amount,
        uint256 bonusRate
    );
    event PaidReferre(address to, uint256 amount);
    event UpdatedUserLastActiveTime(address user, uint256 timestamp);

    mapping(address => Account) public accounts;

    mapping(uint256 => ReferralArgs) public referralArgs;

    string public baseUri;
    uint256 public referralBonus;
    uint256 public decimals;
    uint256 public secondsUntilInactive;
    bool public onlyRewardActiveReferrers;

    uint256[] _defaultLowerBound = [1];
    uint256[] _defaultRate;

    mapping(address => bool) public allowedAddresses; //Only these addresses are allowed to call payReferral function

    modifier onlyAllowedAddress() {
        require(allowedAddresses[msg.sender], "Only Allowed Addresses can call");
        _;
    }

    ///
    ///@param _exoTreasury Address of the exoTreasury
    ///@param name Name of the NFT Referral
    ///@param symbol symbol of the NFT Referral
    ///@param _decimals The base decimals for float calc, for example 1000
    ///@param _referralBonus The total referral bonus rate, which will divide by decimals. For example, If you will like to set as 5%, it can set as 50 when decimals is 1000.
    ///@param _secondsUntilInactive The seconds that a user does not update will be seen as inactive.
    ///@param _onlyRewardActiveReferrers The flag to enable not paying to inactive uplines.
    ///
    constructor(
        address _exoTreasury, //random address
        string memory name, //exoReferrals
        string memory symbol, //EXOREFERRALS
        uint256 _decimals, //1000
        uint256 _referralBonus, //30 = 3%
        uint256 _secondsUntilInactive, //one days
        bool _onlyRewardActiveReferrers //false
    ) ERC721(name, symbol) {
        require(_referralBonus <= _decimals, "Referral bonus exceeds 100%");

        decimals = _decimals;
        referralBonus = _referralBonus;
        secondsUntilInactive = _secondsUntilInactive;
        onlyRewardActiveReferrers = _onlyRewardActiveReferrers;
        _defaultRate = [_decimals];
        exoTreasury = _exoTreasury;
    }

    function toggleAllowedAddresses(address _newAllowed) external onlyOwner{
        allowedAddresses[_newAllowed] = !allowedAddresses[_newAllowed];
    }

    function setExoTreasury(address _exoTreasury) external onlyOwner {
        exoTreasury = _exoTreasury;
    }

    function setBaseUri(string memory _newBaseUri) external onlyOwner {
        baseUri = _newBaseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory ids = new uint256[](balanceOf(owner));
        for (uint256 i = 0; i < balanceOf(owner); i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    ///
    ///@dev Utils function for check whether an address has the referrer
    ///
    function hasReferrer(address addr) public view returns (bool) {
        bool hasReferral = accounts[addr].hasReferral;
        if (hasReferral && _exists(accounts[addr].referrerNftId)) 
        return true;
        else 
        return false;
    }

    ///
    ///@dev Get block timestamp with function for testing mock
    ///
    function getTime() public view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    ///
    ///@dev Given a no. of referrals amount to calc in which bonus rate referrer is
    ///@param amount The number of referrees
    ///
    function getRefereeBonusRate(uint256 id, uint256 amount)
        public
        view
        returns (uint256)
    {
        ReferralArgs memory args = referralArgs[id];
        uint256 rate = args.rate[0];
        for (uint256 i = 1; i < args.lowerBound.length; i++) {
            if (amount < args.lowerBound[i]) {
                break;
            }
            rate = args.rate[i];
        }
        return rate;
    }

    function safeMint(address to) internal returns (uint256 tokenId) {
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        return tokenId;
    }

    /// @notice This function will be used to generate the referrals
    function generateReferral(ReferralArgs memory args) external {
        require(
            args.referrerRate > 0,
            "Referral level rate should be greater than zero"
        );
        require(
            (args.referrerRate + args.referreRate) <= decimals,
            "Total rate exceeds 100%"
        );
        require(
            args.lowerBound.length == args.rate.length,
            "lower bound and rate length should be same"
        );

        // Set default referee amount rate as 1ppl -> 100% if lowerbound is empty.
        if (args.lowerBound.length == 0) {
            args.lowerBound = _defaultLowerBound;
            args.rate = _defaultRate;
        }

        uint256 id = safeMint(_msgSender());

        referralArgs[id] = args;
    }

    /// @dev Add an NFT id as referral
    /// @param referrerNftId The NFT id would set as referral id of msg.sender
    /// @return whether success to add upline
    ///
    function addReferrer(uint256 referrerNftId) external returns (bool) {
        if (!_exists(referrerNftId)) {
            emit RegisteredRefererFailed(
                _msgSender(),
                referrerNftId,
                "Referrer Id does not exist"
            );
            return false;
        }
        else if (ownerOf(referrerNftId) == _msgSender()) {
            emit RegisteredRefererFailed(
                _msgSender(),
                referrerNftId,
                "You cannot add your own referral"
            );
            return false;
        } else {
            bool hasReferral = accounts[_msgSender()].hasReferral;
            if (hasReferral && !_exists(accounts[_msgSender()].referrerNftId)) {
                emit RegisteredRefererFailed(
                    _msgSender(),
                    referrerNftId,
                    "Address have been registered upline"
                );
                return false;
            }
        }

        address referrer = ownerOf(referrerNftId);
        Account storage userAccount = accounts[_msgSender()];
        Account storage parentAccount = accounts[referrer];

        userAccount.hasReferral = true;
        userAccount.referrerNftId = referrerNftId;
        userAccount.lastActiveTimestamp = getTime();
        parentAccount.referredCount = parentAccount.referredCount + 1;

        emit RegisteredReferer(_msgSender(), referrerNftId);
        return true;
    }

    function payReferral(
        address user,
        address token,
        uint256 value
    ) external onlyAllowedAddress {
        if(hasReferrer(user)){
            uint256 totalRefferal = payReferralInternal(user, token, value);
            if((value - totalRefferal) > 0)
            IERC20(token).safeTransfer(exoTreasury, (value - totalRefferal));
        }
        else{
            IERC20(token).safeTransfer(exoTreasury, (value));
        }
    }

    ///
    ///@dev This will calc and pay referral to uplines instantly
    ///@param value The number tokens will be calculated in referral process
    ///@return the total referral bonus paid
    ///
    function payReferralInternal(
        address user,
        address token,
        uint256 value
    ) internal returns (uint256) {
        Account memory userAccount = accounts[user];
        ReferralArgs memory args = referralArgs[userAccount.referrerNftId];

        uint256 totalReferal;

        uint256 c = (value * referralBonus) / (decimals); // (3000 * 30)/1000 = 90

        uint256 referrerNftId = userAccount.referrerNftId;
        address parent = ownerOf(referrerNftId);
        Account storage parentAccount = accounts[parent];

        if (
            (onlyRewardActiveReferrers &&
                (parentAccount.lastActiveTimestamp + secondsUntilInactive) >=
                getTime()) || !onlyRewardActiveReferrers
        ) {
            uint256 totalReferralBonus = c;

            address _token = token;
            address _user = user;

            //Referrer Normal

            uint256 parentAmount = (c * args.referrerRate) / (decimals); //for e.g => (90 * 900) / 1000 => 90 * 90% = 81

            uint256 leftOverBonus = totalReferralBonus - parentAmount; // (90 - 81) = 9

            //Referee Normal

            uint256 userAmount;

            if (args.referreRate > 0) {
                userAmount = (leftOverBonus * args.referreRate) / (decimals); //(9 * 100)/1000 => 0.9
                userAccount.usingReferralReward =
                    userAccount.usingReferralReward +
                    userAmount;
                IERC20(_token).safeTransfer(_user, userAmount);
                emit PaidReferre(_user, userAmount); 
            }

            leftOverBonus = leftOverBonus - userAmount; //(9 - 0.9) = 8.1

            uint256 bonus = getRefereeBonusRate(
                userAccount.referrerNftId,
                parentAccount.referredCount
            );
            parentAmount = parentAmount + (bonus * leftOverBonus) / (decimals); //(81 + (100 * 8.1) / 1000)

            totalReferal = parentAmount + userAmount; //(81.81 + 0.9) = 81.9

            parentAccount.reward = parentAccount.reward + parentAmount;
            IERC20(_token).safeTransfer(parent, parentAmount);
            emit PaidReferral(_user, parent, parentAmount, bonus);
        }

        updateActiveTimestamp(user);
        return totalReferal; //81.9
    }

    ///
    ///@dev Developers should define what kind of actions are seens active. By default, payReferral will active _msgSender().
    ///@param user The address would like to update active time
    ///
    function updateActiveTimestamp(address user) internal {
        uint256 timestamp = getTime();
        accounts[user].lastActiveTimestamp = timestamp;
        emit UpdatedUserLastActiveTime(user, timestamp);
    }

    function setSecondsUntilInactive(uint256 _secondsUntilInactive)
        public
        onlyOwner
    {
        secondsUntilInactive = _secondsUntilInactive;
    }

    function setOnlyRewardAActiveReferrers(bool _onlyRewardActiveReferrers)
        public
        onlyOwner
    {
        onlyRewardActiveReferrers = _onlyRewardActiveReferrers;
    }
}
