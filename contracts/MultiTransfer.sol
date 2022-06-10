// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IERC721Upgradeable.sol";
import "./interfaces/IERC20Upgradeable.sol";
import "./token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MultiTransfer is Ownable {

    function sendERC721(address erc721, address recipient, uint256[] memory tokenIds) public {
        uint256 length = tokenIds.length;
        for (uint i = 0; i < length; i++) {
            IERC721Upgradeable(erc721).transferFrom(msg.sender, recipient, tokenIds[i]);
        }
    }

    function distributeSingle(address payable[] memory recipients, uint256 value, address[] memory tokens, uint256 tokenValue) external payable {
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool sent, ) = recipients[i].call{value: value}("");
            require(sent, "Failed to send Ether");

            for (uint256 j = 0; j < tokens.length; j++) {
                IERC20Upgradeable(tokens[j]).transferFrom(msg.sender, recipients[i], tokenValue);
            }
        }
    }

    function distributeMultiple(address[] memory recipients, uint256[] memory values, address[] memory tokens, uint256[] memory tokenValues) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool sent, ) = recipients[i].call{value: values[i]}("");
            require(sent, "Failed to send Ether");

        for (uint256 j = 0; j < tokens.length; j++) {
            IERC20Upgradeable(tokens[j]).transferFrom(msg.sender, recipients[i], tokenValues[j]);
            }
        }
    }

    function distributeTokenSingleValue(address token, address[] memory recipients, uint256 value) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20Upgradeable(token).transferFrom(msg.sender, recipients[i], value);
        }
    }

    function distributeTokenMultipleleValue(address token, address[] memory recipients, uint256[] memory values) external {
        require(recipients.length == values.length, "Length miss match!");
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20Upgradeable(token).transferFrom(msg.sender, recipients[i], values[i]);
        }
    }

    function distributeSingleValue(address payable[] memory recipients, uint256 value) external payable {
        require(msg.value >= value * recipients.length, "Insufficient funds!");
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool sent, ) = recipients[i].call{value: value}("");
            require(sent, "Failed to send Ether");
        }
    }

    function distributeMultipleValue(address payable[] memory recipients, uint256[] memory values) external payable {
        require(recipients.length == values.length, "Length miss match!");
        for (uint256 i = 0; i < recipients.length; i++) {
        (bool sent, ) = recipients[i].call{value: values[i]}("");
        require(sent, "Failed to send Ether");
        }
    }

    function withdrawToken(address token) external onlyOwner {
        IERC20Upgradeable(token).transfer(msg.sender, IERC20Upgradeable(token).balanceOf(address(this)));
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}(new bytes(0));
        require(success, "Failed to withdraw!");
    }

    function withdrawNFTs(address erc721) external onlyOwner {
        uint256 length = IERC721Upgradeable(erc721).balanceOf(address(this));
        for (uint index = 0; index < length; index++) {
            uint256 tokenId = IERC721EnumerableUpgradeable(erc721).tokenOfOwnerByIndex(address(this), 0);
            IERC721Upgradeable(erc721).transferFrom(address(this), msg.sender, tokenId);
        }
    }
}
