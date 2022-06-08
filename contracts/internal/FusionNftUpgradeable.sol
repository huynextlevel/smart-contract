// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../access/AccessControlUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

contract FusionNftUpgradeable is Initializable, ContextUpgradeable, AccessControlUpgradeable {
    event SetFusionContract(address indexed oldFusionContract, address indexed newFusionContract);

    address private _fusionContract;
    
    function __FusionNft_init() internal onlyInitializing {
    }

    function __FusionNft_init_unchained() internal onlyInitializing {
    }

    modifier onlyFusionContract() {
        require(_fusionContract == _msgSender(), "ENFT: caller is not the fusion contract");
        _;
    }

    function setFusionContract(address fusionContract) public onlyRole(ADMIN_ROLE) {
        require(fusionContract != address(0), "FusionNft: new fusion contract is the zero address");
        _setFusionContract(fusionContract);
    }

    function _setFusionContract(address newFusionContract) internal virtual {
        address oldFusionContract = _fusionContract;
        _fusionContract = newFusionContract;
        emit SetFusionContract(oldFusionContract, newFusionContract);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}