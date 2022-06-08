// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./proxy/utils/Initializable.sol";
import "./access/AccessControlUpgradeable.sol";
import "./token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "./interfaces/IERC721Upgradeable.sol";
import "./token/ERC20/IERC20Upgradeable.sol";
import "./token/ERC20/IERC20BurnUpgradeable.sol";
import "./internal/MintingFeeUpgradeable.sol";

interface Metadata{
    function species(uint256) external view returns(uint8, uint8);
    function batchFusion(uint8 ranking, uint8 level, uint256 numbs) external;
}

contract FuseNFT is Initializable, MintingFeeUpgradeable {
    event FuseNFTs(address indexed account, uint256[] tokenIds);

    struct Fusion {
        uint256 id;
        uint8 rank;
        uint8 level;
        uint256 startTime;
        uint256 harvestTime;
        uint256 index;
        bool inserted;
    }

    struct User {
        uint[] fusionIds;
        mapping(uint256 => Fusion) fusionMap;
    }

    mapping(address => User) private users;

    address private _rawContract;
    uint8 private _threshold;
    uint256 private constant ONE_HOUR = 1 hours;

    modifier validLength(uint256[] memory tokenIds) {
        require(tokenIds.length > 0 && tokenIds.length % _threshold == 0, "FuseNFT: Invalid number of NFTs");
        _;
    }

    modifier sameSpecies(uint256[] memory tokenIds) {
        (uint8 rawRanking, uint8 rawLevel) = Metadata(_rawContract).species(tokenIds[0]);
        for (uint256 i = 1; i < tokenIds.length; i++) {
            (uint8 ranking, uint8 level) = Metadata(_rawContract).species(tokenIds[i]);
            require(rawRanking == ranking, "FusionNFT: NFTs do not have the same ranking");    
            require(rawLevel == level, "FusionNFT: NFTs do not have the same level");
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        setThreshHold(8);

    }

    function fuseNfts(uint256[] memory tokenIds) public validLength(tokenIds) sameSpecies(tokenIds) {
        require(tokenIds.length == _threshold, "Insufficient-NFTs!");

        (uint8 rawRanking, uint8 rawLevel) = Metadata(_rawContract).species(tokenIds[0]);
        uint8 newRanking = upgradeRanking(rawRanking);
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721Upgradeable(_rawContract).transferFrom(msg.sender, address(this), tokenIds[i]);
            ERC721BurnableUpgradeable(_rawContract).burn(tokenIds[i]);
        }
        IERC20Upgradeable(feeToken()).transferFrom(_msgSender(), address(this), feeAmount());
        IERC20BurnUpgradeable(feeToken()).burnFrom(_msgSender(), feeAmount());

        User storage user = users[msg.sender];
        uint256 fusionId = block.number;
        user.fusionMap[fusionId] = Fusion(fusionId, newRanking, rawLevel, block.timestamp, block.timestamp + ONE_HOUR * (2 ** (rawLevel - 1)), user.fusionIds.length, true);
        user.fusionIds.push(fusionId);
        emit FuseNFTs(msg.sender, tokenIds);
    }

    function harvest(uint256 fusionId) public {
        User storage user = users[msg.sender];
        Fusion storage fusion = user.fusionMap[fusionId];
        require(fusion.harvestTime >= block.timestamp, "Too-early harvest!");
        require(fusion.inserted, "Invalid id or already harvested!");
        delete fusion.inserted;

        uint256 index = fusion.index;
        delete fusion.index;

        uint256 lastIndex = user.fusionIds.length - 1;
        uint256 lastFusionId = user.fusionIds[lastIndex];

        user.fusionMap[lastFusionId].index = index;
        user.fusionIds[index] = lastFusionId;
        user.fusionIds.pop();
        Metadata(_rawContract).batchFusion(fusion.rank, fusion.level, 1);
    }

    function getFusionIds() public view returns (uint256[] memory) {
        return users[msg.sender].fusionIds;
    }

    function getFusionInfo(uint256 fusionId) public view returns(uint256, uint8, uint8, uint256, uint256) {
        return (
            users[msg.sender].fusionMap[fusionId].id,
            users[msg.sender].fusionMap[fusionId].rank,
            users[msg.sender].fusionMap[fusionId].level,
            users[msg.sender].fusionMap[fusionId].startTime,
            users[msg.sender].fusionMap[fusionId].harvestTime
        );
    }

    function upgradeRanking(uint8 currentRanking) internal pure returns(uint8) {
        return currentRanking + 1;
    }

    function setRawContract(address rawContract) public onlyRole(ADMIN_ROLE) {
        _rawContract = rawContract;
    }

    function threshHold() public view virtual returns (uint8) {
        return _threshold;
    }

    function setThreshHold(uint8 threshold) public onlyRole(ADMIN_ROLE) {
        _threshold = threshold;
    }
}