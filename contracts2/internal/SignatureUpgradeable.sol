// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

abstract contract SignatureUpgradeable is Initializable, ContextUpgradeable {
    event SignerTransferred(address indexed oldSigner, address indexed newSigner);

    address private _signer;

    mapping(address => uint256) private _currentSignedTime;

    function __Signature_init() internal onlyInitializing {
        __Signature_init_unchained();
    }

    function __Signature_init_unchained() internal onlyInitializing {
        _transferSigner(_msgSender());
    }

    modifier onlySigner() {
        require(signer() == _msgSender(), "Signer: caller is not the signer");
        _;
    }

    function signer() public view virtual returns (address) {
        return _signer;
    }

    function getSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function permit(
        bytes32 messageHash,
        uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        require(_currentSignedTime[msg.sender] < timestamp, "Signature: Invalid timestamp");
        return ecrecover(getSignedMessageHash(messageHash), v, r, s) == signer();
    }

    function _setCurrentSignedTime(uint256 timestamp) internal {
        _currentSignedTime[_msgSender()] = timestamp;
    }

    function transferSigner(address newSigner) public virtual onlySigner {
        require(newSigner != address(0), "Signature: new signer is the zero address");
        _transferSigner(newSigner);
    }

    function _transferSigner(address newSigner) internal virtual {
        address oldSigner = _signer;
        _signer = newSigner;
        emit SignerTransferred(oldSigner, newSigner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}