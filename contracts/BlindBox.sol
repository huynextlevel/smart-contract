// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./proxy/utils/Initializable.sol";
import "./access/AccessControlUpgradeable.sol";
import "./token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "./interfaces/IERC721Upgradeable.sol";
import "./token/ERC20/IERC20Upgradeable.sol";

contract BlindBox is Initializable, AccessControlUpgradeable {
    event SetBox(address sellingNft, address listingToken, uint256 listingPrice, address feeBeneficiary);
    event BuyBox(address indexed account, address sellingNft, uint256[] tokenIds);

    struct Box {
        IERC721Upgradeable sellingNft;
        IERC20Upgradeable listingToken;
        uint256 listingPrice;
        address feeBeneficiary;
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
        address listingToken,
        uint256 listingPrice,
        address feeBeneficiary
    ) external onlyRole(ADMIN_ROLE) {
        require(listingPrice > 0, "BlindBox: Invalid price");
        boxes[sellingNft] = Box(
            IERC721Upgradeable(sellingNft),
            IERC20Upgradeable(listingToken),
            listingPrice,
            feeBeneficiary
        );
        emit SetBox(sellingNft, listingToken, listingPrice, feeBeneficiary);
    }

    function getBox(address nft)
        public
        view
        returns (
            IERC721Upgradeable,
            IERC20Upgradeable,
            uint256,
            address
        )
    {
        return (
            boxes[nft].sellingNft,
            boxes[nft].listingToken,
            boxes[nft].listingPrice,
            boxes[nft].feeBeneficiary
        );
    }

    function buy(address nft, uint256 quantity) external validBox(nft) {
        (
            IERC721Upgradeable sellingNft,
            IERC20Upgradeable listingToken,
            uint256 listingPrice,
            address feeBeneficiary
        ) = getBox(nft);

        require(
            sellingNft.balanceOf(address(this)) > quantity,
            "BlindBox: Insufficient boxes"
        );

        require(
            listingToken.transferFrom(msg.sender, feeBeneficiary, listingPrice * quantity),
            "BlindBox: Insufficient balance"
        );
        
        uint256[] memory tokenIds = new uint[](quantity);
        for (uint256 index = 0; index < quantity; index++) {
            uint256 tokenId = IERC721EnumerableUpgradeable(nft).tokenOfOwnerByIndex(address(this), index);
            sellingNft.transferFrom(address(this), msg.sender, tokenId);
            tokenIds[index] = tokenId;
        }
        emit BuyBox(msg.sender, nft, tokenIds);
    }
}
