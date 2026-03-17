// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is ERC721URIStorage, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    uint256 public listingFee = 0.01 ether;

    struct ListedToken {
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isListed;
    }

    mapping(uint256 => ListedToken) public listings;

    event TokenListed(uint256 indexed tokenId, address seller, uint256 price);
    event TokenSold(uint256 indexed tokenId, address buyer, uint256 price);

    constructor() ERC721("NFTMarketplace", "NFTM") {}

    function mintAndList(string memory tokenURI, uint256 price)
        public payable nonReentrant returns (uint256)
    {
        require(msg.value == listingFee, "Wrong listing fee");
        require(price > 0, "Price must be positive");

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);

        listings[tokenId] = ListedToken(tokenId, payable(msg.sender), price, true);
        emit TokenListed(tokenId, msg.sender, price);

        return tokenId;
    }

    function buyToken(uint256 tokenId) public payable nonReentrant {
        ListedToken storage token = listings[tokenId];
        require(token.isListed, "Not listed");
        require(msg.value == token.price, "Wrong price");

        token.isListed = false;
        address payable seller = token.seller;

        _transfer(seller, msg.sender, tokenId);
        seller.transfer(msg.value);

        emit TokenSold(tokenId, msg.sender, msg.value);
    }

    function updateListingFee(uint256 newFee) public onlyOwner {
        listingFee = newFee;
    }
}
