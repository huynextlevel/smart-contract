// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./proxy/utils/Initializable.sol";
import "./access/AccessControlUpgradeable.sol";
import "./token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "./interfaces/IERC721Upgradeable.sol";
import "./token/ERC20/IERC20Upgradeable.sol";

contract BlindBoxV2 is Initializable, AccessControlUpgradeable {
    event SetBox(address sellingNft, uint256 listingPricey);
    event BuyBox(address indexed account, address sellingNft, uint256[] tokenIds);

    struct Box {
        IERC721Upgradeable sellingNft;
        uint256 listingPrice;
    }

    mapping(address => Box) private boxes;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    modifier validBox(address sellingNft) {
        require(
            boxes[sellingNft].listingPrice > 0,
            "BlindBox: Box doesn't exist"
        );
        _;
    }

    function setBox(
        address sellingNft,
        uint256 listingPrice
    ) external onlyRole(ADMIN_ROLE) {
        require(listingPrice > 0, "BlindBox: Invalid price");
        boxes[sellingNft] = Box(IERC721Upgradeable(sellingNft), listingPrice);
        emit SetBox(sellingNft, listingPrice);
    }

    function getBox(address nft)
        public
        view
        returns (
            IERC721Upgradeable,
            uint256
        )
    {
        return (
            boxes[nft].sellingNft,
            boxes[nft].listingPrice
        );
    }

    function buy(address nft, uint256 quantity) external payable validBox(nft) {
        (IERC721Upgradeable sellingNft, uint256 listingPrice) = getBox(nft);

        require(
            sellingNft.balanceOf(address(this)) > quantity,
            "BlindBox: Insufficient boxes"
        );

        require(msg.value >= listingPrice * quantity, "BlindBox: Insufficient balance");
        
        uint256[] memory tokenIds = new uint[](quantity);
        for (uint256 index = 0; index < quantity; index++) {
            uint256 tokenId = IERC721EnumerableUpgradeable(nft).tokenOfOwnerByIndex(address(this), 0);
            sellingNft.transferFrom(address(this), msg.sender, tokenId);
            tokenIds[index] = tokenId;
        }
        emit BuyBox(msg.sender, nft, tokenIds);
    }

    function withdrawToken(address token) external onlyRole(ADMIN_ROLE) {
        IERC20Upgradeable(token).transfer(msg.sender, IERC20Upgradeable(token).balanceOf(address(this)));
    }

    function withdrawMoney() external onlyRole(ADMIN_ROLE) {
        (bool success, ) = (msg.sender).call{value: address(this).balance}(new bytes(0));
        require(success, "Failed to withdraw!");
    }
}
