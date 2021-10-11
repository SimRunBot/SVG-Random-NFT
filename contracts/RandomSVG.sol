// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "base64-sol/base64.sol";

contract RandomSVG is ERC721, VRFConsumerBase {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  mapping(bytes32 => address) internal requestIdToSender;
  mapping(bytes32 => uint) internal requestIdToTokenId;
  mapping(uint => uint) internal tokenIdToRandomNumber;

  event requestedRandomSVG(bytes32 indexed requestId, uint indexed tokenId);
  event CreatedRSVGNFT(uint indexed tokenID, string tokenURI);
  event CreatedUnfinishedRandomSVG(uint indexed, uint randomness);

  // chainlink variables
  bytes32 internal keyHash;
  uint256 internal fee;
  
  // SVG parameters
  uint256 public maxNumberOfCircles;
  uint public size;
  string[] public colors;
  uint[] public radii;

  // rinkeby Chainlink Addresses and fee
  //0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B VRF Coordinator
  //0x01BE23585060835E02B77ef475b0Cc51aA1e0709 LINK Token
  //0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311 keyhash
  // 0.1 * 10 ** 18 fee

  constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash, uint _fee) 
    ERC721("RandomSVG","RSVG") 
    VRFConsumerBase(_VRFCoordinator, _LinkToken)
    {
    keyHash = _keyhash;
    fee = _fee; 
    // initialize range of SVG Parameters to be chosen from
    maxNumberOfCircles = 12;
    size = 500;
    colors = ["blue", "red", "black", "yellow", "green"];
    radii = [10, 20, 30, 40, 50, 60, 70, 80, 90];
  }

  function create() public returns (bytes32 requestId){
    requestId = getRandomNumber();
    requestIdToSender[requestId] = msg.sender;
    uint tokenId = _tokenIds.current();
    requestIdToTokenId[requestId] = tokenId;
    emit requestedRandomSVG(requestId, tokenId);
    _tokenIds.increment();
  }

  // sends request for random number to Chainlink VRF node along with fee
  function getRandomNumber() internal returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
    return requestRandomness(keyHash, fee);
  }

  // callback function called with the returning random value
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    address nftOwner = requestIdToSender[requestId];
    uint tokenId = requestIdToTokenId[requestId];
    _safeMint(nftOwner, tokenId);
    tokenIdToRandomNumber[tokenId] = randomness;
    emit CreatedUnfinishedRandomSVG(tokenId, randomness);
  }

  function tokenURI(uint tokenId) public view override returns(string memory){
    string memory _tokenURI = "Token with that ID does not exist.";
    if (_exists(tokenId)){
      require(tokenIdToRandomNumber[tokenId] > 0, "Need to wait for Chainlink VRF");
      string memory svg = generateSVG(tokenIdToRandomNumber[tokenId]);
      string memory imageURI = svgToImageURI(svg);
      _tokenURI = formatTokenURI(imageURI);
    }
    return _tokenURI;
  }

  function generateSVG(uint _randomNumber) internal view returns(string memory finalSvg){
    /* 
    maxNumberOfCircles = 12;
    size = 500;
    colors = ["blue", "red", "black", "yellow", "green"];
    radii = [10, 20, 30, 40, 50, 60, 70, 80, 90]
    */
    uint numberOfCircles = (_randomNumber % maxNumberOfCircles) + 1;
    finalSvg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' height='", uint2str(size),"' width='", uint2str(size),"'>"));

    for(uint i = 0 ; i < numberOfCircles; i++){
      uint newRNG = uint(keccak256(abi.encode(_randomNumber,i)));
      string memory circleSVG = generateCircle(newRNG);
      finalSvg = string(abi.encodePacked(finalSvg, circleSVG));
    }

    finalSvg = string(abi.encodePacked(finalSvg, "</svg>"));
  }

  function generateCircle(uint randomNumber) public view returns(string memory circleSVG){
    // <circle cx="50%" cy="50%" r="40" stroke="black" stroke-width="1" fill="red" />
    string memory color = colors[randomNumber % colors.length];
    uint radius = radii[randomNumber % radii.length];
    uint anotherRNG = uint(keccak256(abi.encode(randomNumber, radius)));
    uint posX = radii[anotherRNG % radii.length];
    uint andAnotherRNG = uint(keccak256(abi.encode(anotherRNG, posX)));
    uint posY = radii[andAnotherRNG % radii.length];
    circleSVG = string(abi.encodePacked("<circle ", "cx='",uint2str(posX),"%' cy='",uint2str(posY),"%' r='",uint2str(radius),"' stroke='black' stroke-width='1' fill='",color,"' />"));
  }

  function svgToImageURI(string memory svg) public pure returns(string memory){
    string memory baseURL = "data:image/svg+xml;base64,";
    string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
    return string(abi.encodePacked(baseURL, svgBase64Encoded));
  }

  function formatTokenURI(string memory imageURI) public pure returns(string memory){
    string memory baseURL = "data:application/json;base64,";
    return string(
      abi.encodePacked(
        baseURL,
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{"name": "SVG NFT", ', 
              '"description": "An NFT with SVG on chain!", ',
              '"attributes":"", ',
              '"image": "',
              imageURI,
              '"}'
            )
          )
        )
      )
    );
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
  }

}