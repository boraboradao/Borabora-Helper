// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IBoraSwap {
  event AmmStatusChange(
    uint256 ammExBoraAmount,
    uint256 ammUsdtAmount,
    uint256 ammK
  );

  event SwapExBoraToUsdt(
    address indexed owner,
    uint256 exBoraAmount,
    uint256 usdtChangeAmount,
    uint256 usdtAmount,
    uint256 feeAmount
  );

  event SwapUsdtToExBora(
    address indexed owner,
    uint256 usdtAmount,
    uint256 exBoraChangeAmount,
    uint256 exBoraAmount,
    uint256 feeAmount
  );

  event SetIsSwapUsdtToExBoraEnable(bool isEnable);

  event SetSwapFeeRate(uint256 feeRate);

  event SetExBora(address exBora);

  function injectUsdt(uint256 amount) external returns (uint256);

  function addUsdtAmount(uint256 amount) external returns (bool);
}
