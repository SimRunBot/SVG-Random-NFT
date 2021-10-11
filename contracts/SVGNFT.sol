// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "base64-sol/base64.sol";

contract SVGNFT is ERC721{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  mapping(uint => string ) tokenSVGs;
  event CreatedSVGNFT(uint indexed tokenID, string tokenURI);
  constructor() ERC721("SVGNFT","SVGNFT") {

  }

  function create(string memory svg) public {
    _safeMint(msg.sender, _tokenIds.current());
    emit CreatedSVGNFT(_tokenIds.current(), tokenURI(_tokenIds.current()));
    tokenSVGs[_tokenIds.current()] = svg;
    _tokenIds.increment();
    
  }

  function tokenURI(uint tokenId) public view override returns(string memory){
    string memory imageURI = svgToImageURI(tokenSVGs[tokenId]);
    string memory _tokenURI = formatTokenURI(imageURI);
    return _tokenURI;
  }

  function svgToImageURI(string memory svg) public pure returns(string memory){
    string memory baseURL = "data:image/svg+xml;base64,";
    string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
    return string(abi.encodePacked(baseURL, svgBase64Encoded));
  }

  function formatTokenURI(string memory imageURI) public pure returns(string memory){
    string memory baseURL = "data:application/json;base64,";
    return string(abi.encodePacked(baseURL,
      Base64.encode(
        bytes(abi.encodePacked(
          '{"name": "SVG NFT", ', 
          '"description": "An NFT with SVG on chain!", ',
          '"attributes":"", ',
          '"image": "',
          imageURI,
          '"}'
          )))
      )
    );
  }
}