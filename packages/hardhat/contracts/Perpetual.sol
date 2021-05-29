// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PriceConsumerV3.sol";

contract Perpetual is Ownable, PriceConsumerV3XAU {
    IERC20 USDC;

    uint256 public vUSDCreserve;
    uint256 public vXAUreserve;
    uint256 public totalLiquidity;
    uint256 public leverage;

    mapping(address => uint256) public USDCvault;
    mapping(address => uint256) public vXAUlong;
    mapping(address => uint256) public vXAUshort;

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
        bool txstatus = USDC.transfer(address(this), amount);
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

    /*********************** funding Rate *****************************/

    function getFundingRate() public view returns (uint256) {
        uint256 decimals = 10**8;
        uint256 priceIndex = uint256(getXAUPrice());
        uint256 pricePerpetual = (vUSDCreserve * decimals) / vXAUreserve;

        uint256 fundingRate = pricePerpetual - priceIndex;
        return fundingRate;
    }

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
