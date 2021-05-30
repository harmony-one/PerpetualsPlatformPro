// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PriceConsumerV3.sol";

import "hardhat/console.sol";

contract Perpetual is Ownable, PriceConsumerV3XAU {
    IERC20 public USDC;

    // state

    uint256 public vUSDCreserve;
    uint256 public vXAUreserve;
    uint256 public totalLiquidity;
    uint256 public leverage;

    mapping(address => uint256) public USDCvault;

    address[] public vXAUlongHolders;
    mapping(address => uint256) public vXAUlong;

    address[] public vXAUshortHolders;
    mapping(address => uint256) public vXAUshort;

    struct Funding {
        bool isPositive;
        uint256 rate;
    }
    Funding public funding;

    // events
    event Deposit(uint256, address indexed);
    event Withdraw(uint256, address indexed);

    event NewReserves(uint256, uint256);

    event LongXAUminted(uint256, address indexed);
    event ShortXAUminted(uint256, address indexed);

    event LongXAUredeemed(uint256, address indexed);
    event ShortXAUredeemed(uint256, address indexed);

    constructor(
        address token_addr,
        uint256 _vUSDCreserve,
        uint256 _vXAUreserve,
        uint256 _leverage
    ) PriceConsumerV3XAU() {
        USDC = IERC20(token_addr);
        vUSDCreserve = _vUSDCreserve;
        vXAUreserve = _vXAUreserve;
        totalLiquidity = _vUSDCreserve * _vXAUreserve;
        leverage = _leverage;
    }

    function deposit(uint256 amount) public returns (bool) {
        bool txstatus = USDC.transferFrom(msg.sender, address(this), amount);
        require(txstatus, "Transaction failed");
        USDCvault[msg.sender] += amount;
        emit Deposit(amount, msg.sender);
        return txstatus;
    }

    function withdraw(uint256 amount) public returns (bool) {
        require(
            amount <= USDCvault[msg.sender],
            "Can not require more than in balance"
        );
        USDCvault[msg.sender] -= amount;
        bool txstatus = USDC.transfer(msg.sender, amount);
        require(txstatus, "Transaction failed");
        emit Withdraw(amount, msg.sender);
        return txstatus;
    }

    /*********************** LONG POSITION **********************************/
    // open long position

    function _mintVUSDC(uint256 amount) internal returns (uint256) {
        // estimate trades
        uint256 vUSDCreserveNew = vUSDCreserve + amount;
        uint256 vXAUreserveNew = totalLiquidity / vUSDCreserveNew; // x = k / y
        uint256 buy = vXAUreserve - vXAUreserveNew; // vXAU taken from pool

        _updateBalances(vUSDCreserveNew, vXAUreserveNew);

        return buy;
    }

    function MintLongXAU(uint256 amount) public returns (uint256) {
        uint256 USDCowned = USDCvault[msg.sender];
        require(USDCowned >= amount, "USDC balances are too low");
        USDCvault[msg.sender] -= amount;

        uint256 vUSDCnotional = amount * leverage;

        uint256 vXAUbought = _mintVUSDC(vUSDCnotional);
        vXAUlong[msg.sender] += vXAUbought;

        emit LongXAUminted(vXAUbought, msg.sender);

        vXAUlongHolders.push(msg.sender);

        return vXAUbought;
    }

    // close long position

    function _mintVXAU(uint256 amount) internal returns (uint256) {
        // estimate trades
        uint256 vXAUreserveNew = vXAUreserve + amount;
        uint256 vUSDCreserveNew = totalLiquidity / vXAUreserveNew; // x = k / y
        uint256 buy = vUSDCreserve - vUSDCreserveNew; // vUSDC taken from the pool

        _updateBalances(vUSDCreserveNew, vXAUreserveNew);

        return buy;
    }

    function RedeemLongXAU(uint256 amount) public returns (uint256) {
        require(vXAUlong[msg.sender] >= amount, "USDC balances are too low");
        vXAUlong[msg.sender] -= amount;

        uint256 vUSDCbought = _mintVXAU(amount);
        USDCvault[msg.sender] += vUSDCbought / leverage;

        emit LongXAUredeemed(vUSDCbought, msg.sender);
        return vUSDCbought;
    }

    /*********************** SHORT POSITION **********************************/

    // open short position

    function _burnVUSDC(uint256 amount) internal returns (uint256) {
        // estimate trades
        uint256 vUSDCreserveNew = vUSDCreserve - amount;
        uint256 vXAUreserveNew = totalLiquidity / vUSDCreserveNew; // x = k / y
        uint256 buy = vXAUreserveNew - vXAUreserve; // vXAU added to the pool

        _updateBalances(vUSDCreserveNew, vXAUreserveNew);

        return buy;
    }

    function MintShortXAU(uint256 amount) public returns (uint256) {
        require(USDCvault[msg.sender] >= amount, "USDC balances are too low");
        uint256 vUSDCnotional = amount * leverage;
        USDCvault[msg.sender] -= amount;

        uint256 vXAUsold = _burnVUSDC(vUSDCnotional);
        vXAUshort[msg.sender] += vXAUsold;

        emit ShortXAUminted(vXAUsold, msg.sender);

        vXAUshortHolders.push(msg.sender);

        return vXAUsold;
    }

    // close short position

    function _burnVXAU(uint256 amount) internal returns (uint256) {
        // estimate trades
        uint256 vXAUreserveNew = vXAUreserve - amount;
        uint256 vUSDCreserveNew = totalLiquidity / vXAUreserveNew; // x = k / y
        uint256 buy = vUSDCreserveNew - vXAUreserveNew; // vUSDC put back into pool

        _updateBalances(vUSDCreserveNew, vXAUreserveNew);

        return buy;
    }

    function RedeemShortXAU(uint256 amount) public returns (uint256) {
        require(vXAUshort[msg.sender] >= amount, "USDC balances are too low");
        vXAUshort[msg.sender] -= amount;

        uint256 vUSDCbought = _burnVXAU(amount);
        USDCvault[msg.sender] += vUSDCbought / leverage;

        emit ShortXAUredeemed(vUSDCbought, msg.sender);
        return vUSDCbought;
    }

    /*********************** getter function *****************************/

    function getPrice() public view returns (uint256) {
        return (vUSDCreserve * 10**18) / vXAUreserve;
    }

    /*********************** funding Rate *****************************/
    // calculate global funding rate
    /*
    function updateFundingRate() public onlyOwner {
        uint256 decimals = 10**8;
        uint256 priceIndex = uint256(getXAUPrice());
        uint256 pricePerpetual = (vUSDCreserve * decimals) / vXAUreserve;

        if (priceIndex >= pricePerpetual) {
            funding.isPositive = true;
            funding.rate =
                ((priceIndex - pricePerpetual) * decimals) /
                (priceIndex * 24);
        } else {
            funding.isPositive = false;
            funding.rate =
                ((pricePerpetual - priceIndex) * decimals) /
                (priceIndex * 24);
        }
    }

    function _loop_throug_array(
        uint256 _fundingRate,
        bool _isPositive,
        address[] memory holders,
        mapping(address => uint256) memory balances
    ) internal {
        uint256 decimals = 10**8;

        for (uint256 i = 0; i < holders.length; i++) {
            if (_isPositive) {
                balances[holders[i]] +=
                    (balances[holders[i]] * _fundingRate) /
                    decimals;
            } else {
                balances[holders[i]] -=
                    (balances[holders[i]] * _fundingRate) /
                    decimals;
            }
        }
    }

    function _applyRateToLongs(uint256 _fundingRate, bool _isPositive)
        internal
    {
        address[] memory longHolders = vXAUlongHolders;
        mapping(address => uint256) memory longBalances = vXAUlong;
        _loop_throug_array(
            _fundingRate,
            _isPositive,
            longHolders,
            longBalances
        );
    }

    function _applyRateToShorts(uint256 _fundingRate, uint256 _isPositive)
        internal
    {
        /*address[] public vXAUshortHolders;
        mapping(address => uint256) public vXAUshort;
    }

    // apply funding rate to balances in loop (better: create global constant)
    function applyFundingRate() public view onlyOwner {
        Funding memory fundingPayments = funding;
        _applyRateToLongs(fundingPayments.rate, fundingPayments.isPositive);
        _applyRateToShorts(fundingPayments.rate, fundingPayments.isPositive);
    }
    */
    /*********************** helper **********************************/

    function _updateBalances(uint256 vUSDCreserveNew, uint256 vXAUreserveNew)
        internal
    {
        // update balances
        vUSDCreserve = vUSDCreserveNew;
        vXAUreserve = vXAUreserveNew;

        emit NewReserves(vUSDCreserveNew, vXAUreserveNew);
    }
}
