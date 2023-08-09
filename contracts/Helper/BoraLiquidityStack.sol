// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./BoraHelperStorage.sol";
import "./interface/IBoraLiquidityStack.sol";
import "../Pool/interface/IPoolLiquidityHandler.sol";
import "../ExBora/interface/IExBoraLock.sol";

abstract contract BoraLiquidityStack is IBoraLiquidityStack, BoraHelperStorage {
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using ECDSA for bytes32;

  CountersUpgradeable.Counter public stackCounter;
  uint256 public unstackingFeeRate;

  mapping(uint256 => Stack) private _stacks; // lockId => StackLiquidityRequest

  uint256[50] private __gap;

  function approve(
    address token,
    address spender,
    uint256 amount
  ) public onlyOwner returns (bool) {
    SafeERC20.safeApprove(IERC20(token), spender, amount);
    return true;
  }

  function stackLiquidity(uint256 amount) public returns (uint256) {
    // Step 1. Transfer LP-Token to this contract
    uint256 beforeLPTokenBalance = IERC20(boraPVE).balanceOf(address(this));
    SafeERC20.safeTransferFrom(
      IERC20(boraPVE),
      msg.sender,
      address(this),
      amount
    );
    require(
      IERC20(boraPVE).balanceOf(address(this)) >= beforeLPTokenBalance + amount,
      "BoraLiquidityStack: Failed to charge LP-Token"
    );

    // Step 4. Record Stack Liquidity Request
    stackCounter.increment();
    uint256 stackId = stackCounter.current();
    _stacks[stackId] = Stack({
      user: msg.sender,
      startDate: getDate(),
      isRemoveLiquidity: false,
      amount: amount
    });

    emit StackLiquidity(stackId, _stacks[stackId]);
    return stackId;
  }

  function unstackLiquidity(uint256 stackId) public returns (bool) {
    Stack memory stack = _stacks[stackId];

    require(
      stack.user == msg.sender,
      "BoraLiquidityStack: Caller is not the owner of the stackId"
    );

    // Step 3. If stack less then 3 days, charge fee
    uint256 unstackingLPFee;
    uint256 refoundLPAmount = stack.amount;
    if (getDate() - stack.startDate < 3) {
      unstackingLPFee = Price.mulE4(stack.amount, unstackingFeeRate);
      refoundLPAmount = refoundLPAmount - unstackingLPFee;
    }

    _stacks[stackId].isRemoveLiquidity = true;
    _stacks[stackId].amount = refoundLPAmount;
    _stacks[stackId].startDate = getDate();

    IPoolLiquidityHandler(boraPVE).requestLiquidityChange(
      refoundLPAmount,
      false
    );

    emit UnstackLiquidity(stackId, unstackingLPFee, _stacks[stackId]);
    return true;
  }

  function claimUsdt(
    uint256 stackId,
    uint256 requestId,
    bytes memory signature
  ) public returns (bool) {
    require(
      isValidClaimSignature(stackId, requestId, signature),
      "BoraLiquidityStack: Invalid Signature"
    );

    uint256 beforePoolTokenBalance = IERC20(usdt).balanceOf(address(this));
    IPoolLiquidityHandler(boraPVE).claimLiquidityChange(requestId);
    uint256 receiveUsdtAmount = IERC20(usdt).balanceOf(address(this)) -
      beforePoolTokenBalance;

    SafeERC20.safeTransfer(IERC20(usdt), msg.sender, receiveUsdtAmount);

    delete _stacks[stackId];

    emit ClaimUsdt(stackId, receiveUsdtAmount);
    return true;
  }

  function isValidClaimSignature(
    uint256 stackId,
    uint256 poolRequestId,
    bytes memory signature
  ) public view returns (bool) {
    bytes32 msgHash = keccak256(
      abi.encodePacked("BoraStack", msg.sender, stackId, poolRequestId)
    );

    address signer = msgHash.toEthSignedMessageHash().recover(signature);
    return isExecutor(signer);
  }

  function setUnstackingFeeRate(uint256 feeRate) external onlyOwner {
    unstackingFeeRate = feeRate;
    emit SetUnstackingFeeRate(feeRate);
  }

  function getDate() public view returns (uint64) {
    return uint64(block.timestamp / 1 days);
  }

  function getStack(uint256 stackId) public view returns (Stack memory) {
    return _stacks[stackId];
  }
}
