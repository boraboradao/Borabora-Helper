// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./BoraHelperStorage.sol";
import "./BoraAirdrop.sol";
import "./BoraSwap.sol";
import "./BoraLiquidityStack.sol";

contract BoraHelper is
  Initializable,
  OwnableUpgradeable,
  UUPSUpgradeable,
  BoraHelperStorage,
  BoraAirdrop,
  BoraSwap,
  BoraLiquidityStack
{
  receive() external payable {}

  function initialize(
    address boraPVE_,
    address usdt_,
    address boraLock_
  ) public initializer {
    __Ownable_init();
    _storageIntialize(boraPVE_, usdt_, boraLock_);
  }

  function withdraw(
    address tokenAddr,
    address to,
    uint256 amount
  ) external onlyOwner {
    if (tokenAddr == address(0)) {
      bool isSuccess = payable(to).send(amount);
      require(isSuccess, "Failed to send Platform Token");
    } else {
      SafeERC20.safeTransfer(IERC20(tokenAddr), to, amount);
    }
  }

  function _authorizeUpgrade(
    address newImplementation
  ) internal virtual override onlyOwner {}
}
