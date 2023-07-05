// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC721 Token contract
 * @author memolabs
 * @notice Used to generate nft from the files that in user's network disk
 */
// _setTokenURI(uint256 tokenId, string memory _tokenURI)
// _burn(uint256 tokenId) internal virtual override
// _safeMint(address to, uint256 tokenId)
contract ERC721Token is Ownable, ERC721Pausable, ERC721URIStorage, ERC721Enumerable {

    struct TokenData {
        string keyword;
        string description;
    }

    // the key is tokenId
    mapping(uint256 => TokenData) public tokenData;

    event SetTokenURI(uint256 indexed tokenId, string tokenURI);
    event SetTokenData(uint256 indexed tokenId, TokenData _tokenData);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        ERC721Pausable._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        ERC721Enumerable._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        ERC721URIStorage._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _safeTransfer(from, to, tokenId, data);
    }

    function safeMint(address to, uint256 tokenId, string memory _tokenURI, TokenData memory _tokenData) public {
        _safeMint(to, tokenId);
        
        _setTokenURI(tokenId, _tokenURI);

        tokenData[tokenId] = _tokenData;

        emit SetTokenURI(tokenId, _tokenURI);
        emit SetTokenData(tokenId, _tokenData);
    }

    function safeMint(address to, uint256 tokenId, string memory _tokenURI, TokenData memory _tokenData, bytes memory data) public {
        _safeMint(to, tokenId, data);

        _setTokenURI(tokenId, _tokenURI);

        tokenData[tokenId] = _tokenData;

        emit SetTokenURI(tokenId, _tokenURI);
        emit SetTokenData(tokenId, _tokenData);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Token: caller is not token owner or approved");
        
        _setTokenURI(tokenId, _tokenURI);
        
        emit SetTokenURI(tokenId, _tokenURI);
    }

    function setTokenData(uint256 tokenId, TokenData memory _tokenData) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Token: caller is not token owner or approved");
        
        tokenData[tokenId] = _tokenData;

        emit SetTokenData(tokenId, _tokenData);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Token: caller is not token owner or approved");
        _burn(tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
