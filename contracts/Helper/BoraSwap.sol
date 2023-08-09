// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./BoraHelperStorage.sol";
import "./interface/IBoraSwap.sol";

abstract contract BoraSwap is IBoraSwap, BoraHelperStorage {
  /**
   * BoraSwap Related Variables & Functions
   **/
  address public exBora;
  uint256 public ammFixedK;
  uint256 public ammExBoraAmount;
  uint256 public ammUsdtAmount;
  uint256 public swapFeeRate;

  bool public isSwapUsdtToExBoraEnable;

  uint256[50] private __gap;

  function swapExBoraToUsdt(uint256 exboraAmount) external returns (uint256) {
    uint256 beforeExBoraBalance = IERC20(exBora).balanceOf(address(this));
    SafeERC20.safeTransferFrom(
      IERC20(exBora),
      msg.sender,
      address(this),
      exboraAmount
    );

    require( // check if exBora's balance is increased
      IERC20(exBora).balanceOf(address(this)) >=
        beforeExBoraBalance + exboraAmount,
      "BoraSwap: Failed to transfer exBora"
    );

    uint256 usdtChangeAmount = predictUsdtChangeAmout(exboraAmount);
    ammExBoraAmount += exboraAmount;
    ammUsdtAmount -= usdtChangeAmount;

    uint256 feeAmount = Price.mulE4(usdtChangeAmount, swapFeeRate);
    uint256 returnAmount = usdtChangeAmount - feeAmount;

    // transfer USDT to user
    SafeERC20.safeTransfer(IERC20(usdt), msg.sender, returnAmount);

    emit SwapExBoraToUsdt(
      msg.sender,
      exboraAmount,
      usdtChangeAmount,
      returnAmount,
      feeAmount
    );
    emit AmmStatusChange(ammExBoraAmount, ammUsdtAmount, ammFixedK);
    return returnAmount;
  }

  function swapUsdtToExBora(uint256 usdtAmount) public returns (uint256) {
    require(isSwapUsdtToExBoraEnable, "BoraSwap: Swap is not enabled");

    uint256 beforeUsdtBalance = IERC20(usdt).balanceOf(address(this));
    SafeERC20.safeTransferFrom(
      IERC20(usdt),
      msg.sender,
      address(this),
      usdtAmount
    );
    require(
      IERC20(usdt).balanceOf(address(this)) >= beforeUsdtBalance + usdtAmount,
      "BoraSwap: Failed to transfer USDT"
    );

    uint256 exBoraChangeAmount = predictExBoraChangeAmount(usdtAmount);
    ammExBoraAmount -= exBoraChangeAmount;
    ammUsdtAmount += usdtAmount;

    uint256 feeAmount = Price.mulE4(exBoraChangeAmount, swapFeeRate);
    uint256 returnAmount = exBoraChangeAmount - feeAmount;

    emit SwapUsdtToExBora(
      msg.sender,
      usdtAmount,
      beforeUsdtBalance,
      returnAmount,
      feeAmount
    );
    emit AmmStatusChange(ammExBoraAmount, ammUsdtAmount, ammFixedK);
    return exBoraChangeAmount;
  }

  function injectUsdt(
    uint256 usdtAmount
  ) public onlyExecutor returns (uint256) {
    uint256 beforeUsdtBalance = IERC20(usdt).balanceOf(address(this));
    SafeERC20.safeTransferFrom(
      IERC20(usdt),
      msg.sender,
      address(this),
      usdtAmount
    );
    require(
      IERC20(usdt).balanceOf(address(this)) >= beforeUsdtBalance + usdtAmount,
      "BoraSwap: Failed to transfer USDT"
    );

    uint256 exBoraChangeAmount = predictExBoraChangeAmount(usdtAmount);
    ammExBoraAmount -= exBoraChangeAmount;
    ammUsdtAmount += usdtAmount;

    emit AmmStatusChange(ammExBoraAmount, ammUsdtAmount, ammFixedK);
    return exBoraChangeAmount;
  }

  function addUsdtAmount(uint256 amount) public onlyExecutor returns (bool) {
    uint256 exBoraChangeAmount = predictExBoraChangeAmount(amount);
    ammExBoraAmount -= exBoraChangeAmount;
    ammUsdtAmount += amount;

    emit AmmStatusChange(ammExBoraAmount, ammUsdtAmount, ammFixedK);
    return true;
  }

  function predictUsdtChangeAmout(
    uint256 exboraAmount
  ) public view returns (uint256) {
    return ammUsdtAmount - ammFixedK / (ammExBoraAmount + exboraAmount);
  }

  function predictExBoraChangeAmount(
    uint256 usdtAmount
  ) public view returns (uint256) {
    return ammExBoraAmount - ammFixedK / (ammUsdtAmount + usdtAmount);
  }

  function setExBora(address exbora) external onlyOwner {
    exBora = exbora;
    emit SetExBora(exbora);
  }

  function setSwapFeeRate(uint256 feeRate) external onlyOwner {
    require(swapFeeRate <= 10000, "BoraSwap: Invalid Fee Rate");
    swapFeeRate = feeRate;
    emit SetSwapFeeRate(feeRate);
  }

  function setIsSwapUsdtToExBoraEnable(bool isEnabled) external onlyOwner {
    isSwapUsdtToExBoraEnable = isEnabled;
    emit SetIsSwapUsdtToExBoraEnable(isEnabled);
  }

  function setAMM(
    uint256 exBoraAmount,
    uint256 usdtAmount,
    uint256 ammK
  ) external onlyOwner {
    require(
      exBoraAmount * usdtAmount == ammK,
      "BoraSwap: Invalid AMM Setup Infos"
    );
    ammExBoraAmount = exBoraAmount;
    ammUsdtAmount = usdtAmount;
    ammFixedK = ammK;

    emit AmmStatusChange(ammExBoraAmount, ammUsdtAmount, ammK);
  }
}
