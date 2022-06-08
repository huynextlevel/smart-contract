// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../common/AccessController.sol";
import "../common/FusionNFT.sol";

contract NelonNFT is ERC721, ERC721Burnable, AccessController, FusionNFT {
    using Strings for uint256;

    event BatchMint(address indexed account, uint256[] tokenIds, Ranking ranking, uint8 level, uint256 hashRate, uint256 quantity);
    using Counters for Counters.Counter;

    string public baseExtension = ".json";

    uint private constant COMMON_BASE = 0;
    uint private constant UNCOMMON_BASE = 200;
    uint private constant RARE_BASE = 300;
    uint private constant EPIC_BASE = 400;
    uint private constant LEGEND_BASE = 500;
    
    // Enum representing for classification NFT
    enum Ranking {
        Common,
        Uncommon,
        Rare,
        Epic,
        Legend
    }

    struct Species {
        Ranking ranking;
        uint8 level;
        uint256 hashRate;
    }

    // Base URI for metadata to be accessed at.
    string private _uri;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => Species) public species;

    constructor() ERC721("NelonNFT", "NLNFT") {
        _setupRole(ADMIN, _msgSender());
    }

    function setBaseURI(string memory _newURI) public onlyAdmin {
        _uri = _newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function batchMint(uint8 level, uint256 quantity) public {
        require(level == 1, "NELONNFT: Just allow for NFT lv1.");

        _batchMint(Ranking.Common, level, quantity);
    }

    function batchFusion(Ranking ranking, uint8 level, uint256 quantity) public onlyFusionContract {
        _batchMint(ranking, level, quantity);
    }

    function _batchMint(Ranking ranking, uint8 level, uint256 quantity) internal {
        uint256[] memory tokenIds = new uint[](quantity);
        uint256 hashRate = generateHashrate(ranking, level);
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            species[tokenId] = Species(ranking, level, hashRate);
            tokenIds[i] = tokenId;
            _safeMint(msg.sender, tokenId);   
        }
        emit BatchMint(msg.sender, tokenIds, ranking, level, hashRate, quantity);
    }

    // Function generate hash rate based on level and ranking
    function generateHashrate(Ranking ranking, uint256 _level) internal pure returns(uint256 _hashRate) {
        require(_level >= 1 && _level <= 50, "NELONNFT: Level is out of range.");
        uint256 level = _level >= 10 ? _level : _level * 10;

        if (ranking == Ranking.Common) {
            _hashRate = COMMON_BASE + level;
        } else if (ranking == Ranking.Uncommon) {
            _hashRate = UNCOMMON_BASE + level;
        } else if (ranking == Ranking.Rare) {
            _hashRate = RARE_BASE + level;
        } else if (ranking == Ranking.Epic) {
            _hashRate = EPIC_BASE + level;
        } else if (ranking == Ranking.Legend) {
            _hashRate = LEGEND_BASE + level;
        }
    }


    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

}