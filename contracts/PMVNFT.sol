//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract PMVNFT is ERC721URIStorage, Ownable {
    // using SafeMath for uint256;
    
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    constructor () ERC721("PrometaV NFT","PMVNFT"){}
    
    function mintNFT(address _to, string memory _tokenURI) public onlyOwner returns(uint256) {
        
        // require(_to != address(0), "ERC721: mintTo: to address is the zero address");
        // require(_tokenId > 0, "ERC721: mintTo: token ID must be a positive integer");
        // require(ERC721.ownerOf(_tokenId) == address(0), "ERC721: mintTo: token with the given ID already exists");
        // ERC721.mint(_to, _tokenId);

        _tokenIds.increment(); //used by counter to get a unique id
        uint256 newItemId = _tokenIds.current(); //used by counters.sol lib
        _mint(_to, newItemId);
        _setTokenURI(newItemId, _tokenURI); //erc721 lib to register item and link with nft
        return newItemId;
    }
    
}
