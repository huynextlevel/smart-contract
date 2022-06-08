// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./token/ERC20/IERC20Upgradeable.sol";
import "./token/ERC20/IERC20BurnUpgradeable.sol";
import "./token/ERC721/ERC721Upgradeable.sol";
import "./token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "./access/AccessControlUpgradeable.sol";
import "./proxy/utils/Initializable.sol";
import "./utils/CountersUpgradeable.sol";
import "./internal/SignatureUpgradeable.sol";
import "./internal/MintingFeeUpgradeable.sol";
import "./internal/FusionNftUpgradeable.sol";

contract EnergyNFT is Initializable, ERC721Upgradeable, ERC721BurnableUpgradeable, AccessControlUpgradeable, SignatureUpgradeable, MintingFeeUpgradeable, FusionNftUpgradeable {
    event BatchMint(address indexed account, uint256[] tokenIds, Ranking ranking, uint8 level, uint256 numbs);

    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FUSION_ROLE = keccak256("FUSION_ROLE");

    // Base URI for metadata to be accessed at.
    string private _uri;
    mapping(uint256 => Species) private _species;
    CountersUpgradeable.Counter private _tokenIdCounter;

    // Enum representing for classification NFT
    enum Ranking {
        Legend,
        Mythic,
        Special
    }

    struct Species {
        Ranking ranking;
        uint8 level;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("EnergyNFT", "ENFT");
        __ERC721Burnable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function getMessageHash(
        address account,
        uint8 level,
        uint256 numbs,
        uint256 timestamp
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, level, numbs, timestamp));
    }

    function batchMint(uint8 level, uint256 numbs, uint256 timestamp, uint8 v, bytes32 r, bytes32 s) public {
        require(permit(getMessageHash(msg.sender, level, numbs, timestamp), timestamp, v, r, s), "Minting: Invalid signal");
        IERC20BurnUpgradeable(feeToken()).burnFrom(msg.sender, feeAmount() * numbs);
        _setCurrentSignedTime(timestamp);
        _batchMint(Ranking.Legend, level, numbs);
    }

    function batchFusion(Ranking ranking, uint8 level, uint256 numbs) public onlyRole(FUSION_ROLE) {
        _batchMint(ranking, level, numbs);
    }

    function _batchMint(Ranking ranking, uint8 level, uint256 numbs) internal {
        uint256[] memory tokenIds = new uint[](numbs);
        for (uint256 index = 0; index < numbs; index++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _species[tokenId] = Species(ranking, level);
            tokenIds[index] = tokenId;
            _safeMint(msg.sender, tokenId);   
        }
        emit BatchMint(msg.sender, tokenIds, ranking, level, numbs);
    }

    function species(uint256 tokenId) public view returns (Ranking, uint8) {
        return (_species[tokenId].ranking, _species[tokenId].level);
    }

    function setBaseURI(string memory _newURI) public onlyRole(ADMIN_ROLE) {
        _uri = _newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
