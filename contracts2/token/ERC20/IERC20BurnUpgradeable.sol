// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20BurnUpgradeable {
    function burnFrom(address from, uint256 amount) external returns (bool);
}
