// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPerpetual {
    /*********************** state transitions ***************************/
    function deposit(uint256 amount) external returns (bool);

    function withdraw(uint256 amount) external returns (bool);

    function MintLongXAU(uint256 amount) external returns (uint256);

    function RedeemLongXAU(uint256 amount) external returns (uint256);

    function MintShortXAU(uint256 amount) external returns (uint256);

    function RedeemShortXAU(uint256 amount) external returns (uint256);

    function updateFundingRate() external;

    /*********************** getter functions **********************************/
    function getPrice() external view returns (uint256);

    function getUSDCvault(address _address) external view returns (uint256);

    function getvXAUlong(address _address) external view returns (uint256);

    function getvXAUshort(address _address) external view returns (uint256);

    function getvUSDCreserve() external view returns (uint256);

    function getvXAUreserve() external view returns (uint256);
}
