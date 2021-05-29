// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

//import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Perpetual is Ownable {
    //using SafeMath for uint256;
    IERC20 USDC;

    uint256 public vUSDCreserve;
    uint256 public vXAUreserve;
    uint256 public totalLiquidity;
    uint256 public leverage;

    mapping(address => uint256) public USDCvault;
    mapping(address => uint256) public vXAUlong;
    mapping(address => uint256) public vXAUshort;

    event Deposit(uint256, address indexed);

    event NewReserves(uint256, uint256);

    event LongXAUminted(uint256, address indexed);
    event ShortXAUminted(uint256, address indexed);

    event LongXAUredeemed(uint256, address indexed);
    event ShortXAUredeemed(uint256, address indexed);

    constructor(
        address token_addr,
        uint256 _vUSDCreserve,
        uint256 _vXAUreserve,
        uint256 _totalLiquidity,
        uint256 _leverage
    ) public {
        USDC = IERC20(token_addr);
        vUSDCreserve = _vUSDCreserve;
        vXAUreserve = _vXAUreserve;
        totalLiquidity = _vUSDCreserve * _vXAUreserve;
        leverage = _leverage;
    }

    function deposit(uint256 amount) public returns (bool) {
        bool txstatus = token.transfer(address(this), amount);
        require(txstatus, "Transaction failed");
        USDCvault[msg.sender] += amount;
        emit Deposit(amount, msg.sender);
        return txstatus;
    }

    function _updateBalances(uint256 vUSDCreserveNew, uint256 vXAUreserveNew)
        internal
    {
        // update balances
        vUSDCreserve = vUSDCreserveNew;
        vXAUreserve = vXAUreserveNew;

        emit NewReserves(vUSDCreserveNew, vXAUreserveNew);
    }

    // long position

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

    // short position

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

        uint256 vXAUsold = _deriveUSDC(vUSDCnotional);
        vXAU[msg.sender] += vXAUsold;

        emit ShortXAUminted(vXAUsold, msg.sender);
        return vXAUsold;
    }
}
