// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BoraHelperStorage.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interface/IBoraAirdrop.sol";

abstract contract BoraAirdrop is IBoraAirdrop, BoraHelperStorage {
  using SafeERC20 for IERC20;
  using ECDSA for bytes32;

  uint256 public airdropSignatureLifetime; // 60 seconds = 1 minutes
  mapping(uint256 => bool) private _airdropSignatures;

  uint256[50] private __gap;

  function claimAirdrop(
    uint256 signatureId,
    address tokenAddr,
    uint256 amount,
    uint256 timestamp,
    bytes memory signature
  ) external {
    require(
      isAirdropSignatureUsed(signatureId) == false,
      "Airdrop: Signature Used"
    );
    _airdropSignatures[signatureId] = true;

    require(
      timestamp + airdropSignatureLifetime > block.timestamp,
      "Airdrop: Signature Expired"
    );
    require(
      isValidAirdropSignature(
        signatureId,
        tokenAddr,
        amount,
        timestamp,
        signature
      ),
      "Airdrop: Invalid Signature"
    );

    if (tokenAddr == address(0)) {
      bool isSuccess = payable(msg.sender).send(amount);
      require(isSuccess, "Airdrop: Failed to send Platform Token");
    } else {
      uint8 tokenDecimals = ERC20(tokenAddr).decimals();
      amount = _convertDecimals(amount, 18, tokenDecimals);
      SafeERC20.safeTransfer(IERC20(tokenAddr), msg.sender, amount);
    }

    emit ClaimAirdrop(msg.sender, signatureId, tokenAddr, amount);
  }

  function isValidAirdropSignature(
    uint256 signatureId,
    address tokenAddr,
    uint256 amount,
    uint256 timestamp,
    bytes memory signature
  ) internal view returns (bool) {
    bytes32 hash = keccak256(
      abi.encodePacked(
        "BORA_AIRDROP",
        msg.sender,
        signatureId,
        tokenAddr,
        amount,
        timestamp
      )
    );
    address executor = hash.toEthSignedMessageHash().recover(signature);

    return isExecutor(executor);
  }

  function setAirdropSignatureLifetime(uint256 lifetime) external onlyOwner {
    airdropSignatureLifetime = lifetime;
    emit SetAirdropSignatureLifetime(lifetime);
  }

  function isAirdropSignatureUsed(
    uint256 signatureId
  ) public view returns (bool) {
    return _airdropSignatures[signatureId];
  }

  function _convertDecimals(
    uint256 amount,
    uint8 fromDecimals,
    uint8 toDecimals
  ) internal pure returns (uint256) {
    if (fromDecimals == toDecimals) {
      return amount;
    } else if (fromDecimals < toDecimals) {
      return amount * (10 ** (toDecimals - fromDecimals));
    } else {
      return amount / (10 ** (fromDecimals - toDecimals));
    }
  }
}
