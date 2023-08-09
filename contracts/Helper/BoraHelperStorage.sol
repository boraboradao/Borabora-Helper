// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../library/Price.sol";

import "./interface/IBoraHelperStorage.sol";

abstract contract BoraHelperStorage is IBoraHelperStorage, OwnableUpgradeable {
  /**
   * Shared Variables & functions
   **/
  address public boraPVE;
  address public usdt;
  address public exBoraLock;
  mapping(address => bool) private _executors;

  uint256[50] private __gap;

  modifier onlyExecutor() {
    require(isExecutor(msg.sender), "BoraHelper: Caller is not Executor");
    _;
  }

  function _storageIntialize(
    address boraPVE_,
    address usdt_,
    address boraLock
  ) internal {
    setBoraPVE(boraPVE_);
    setUsdt(usdt_);
    setExBoraLock(boraLock);
  }

  function setBoraPVE(address pool) public onlyOwner {
    boraPVE = pool;
    emit SetBoraPVE(pool);
  }

  function setUsdt(address token) public onlyOwner {
    usdt = token;
    emit SetUsdt(token);
  }

  function setExBoraLock(address lock) public onlyOwner {
    exBoraLock = lock;
    emit SetExBoraLock(lock);
  }

  function setExecutors(
    address[] memory executors,
    bool isValid
  ) public onlyOwner {
    for (uint256 i = 0; i < executors.length; i++) {
      _executors[executors[i]] = isValid;

      emit SetExecutor(executors[i], isValid);
    }
  }

  function isExecutor(address executor) public view returns (bool) {
    return _executors[executor];
  }
}
