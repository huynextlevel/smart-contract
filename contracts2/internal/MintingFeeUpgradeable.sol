// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../access/AccessControlUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

contract MintingFeeUpgradeable is Initializable, AccessControlUpgradeable {
    event SetMintingFee(address indexed token, uint256 amount);

    address private _feeToken;
    uint256 private _feeAmount;

    function __MintingFee_init() internal onlyInitializing {
    }

    function __MintingFee_init_unchained() internal onlyInitializing {
    }

    function feeToken() public view virtual returns (address) {
        return _feeToken;
    }

    function feeAmount() public view virtual returns (uint256) {
        return _feeAmount;
    }

    function seeMintingFee(address token, uint256 amount) public onlyRole(ADMIN_ROLE) {
        _feeToken = token;
        _feeAmount = amount;
        emit SetMintingFee(token, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}