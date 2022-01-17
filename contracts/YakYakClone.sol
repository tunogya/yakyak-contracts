// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./YakYakRewards.sol";

contract Yaklon is Initializable, ERC721Upgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
  address private _token;
  State private _state;
  string private _nftBaseURI;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(address tokenAddress_, string memory nftBaseURI_) initializer public {
    __ERC721_init("Yaklon", "YAKLON");
    __ERC721Burnable_init();
    __Ownable_init();
    __UUPSUpgradeable_init();

    _token = tokenAddress_;
    _nftBaseURI = nftBaseURI_;
  }

  event DnaCreated(uint64 indexed id);
  event NewSeriesStarted(uint64 indexed newSeriesID);
  event SetCreated(uint64 indexed setID, uint64 indexed series);
  event DnaAddedToSet(uint64 indexed setID, uint64 indexed dnaID);
  event DnaRetiredFromSet(uint64 indexed setID, uint64 indexed dnaID, uint256 numNFTs);
  event SetLocked(uint64 indexed setID);
  event YaklonMinted(uint256 indexed tokenID, uint64 indexed dnaID, uint64 indexed setID, uint256 serialID);
  event YaklonDestroyed(uint256 indexed tokenID);
  event Withdraw(address indexed account, uint256 amount);
  event YaklonFed(uint256 indexed tokenID, uint256 amount);
  event BaseURIUpdate(string newBaseURI);

  mapping(uint64 => DNA) private _dnas;
  mapping(uint64 => Set) private _sets;
  mapping(uint256 => NFT) private _nfts;

  struct State {
    uint64 currentSeries;
    uint64 nextDnaID;
    uint64 nextSetID;
    uint256 nextYaklonID;
  }

  struct NFT {
    uint256 tokenID;
    uint256 serialID;
    uint256 feed;
    uint64 dnaID;
    uint64 setID;
  }

  struct DNA {
    uint64 dnaID;
    string metadata;
  }

  struct Set {
    uint64 setID;
    uint64 series;
    uint64[] dnas;
    string name;
    bool locked;
    mapping(uint64 => bool) retired;
    mapping(uint64 => bool) added;
    mapping(uint64 => uint256) minted;
  }

  function _authorizeUpgrade(address newImplementation)
  internal
  onlyOwner
  override
  {}

  function totalSupply() public view returns (uint256) {
    return _state.nextYaklonID;
  }

  function getToken() public view returns (address) {
    return _token;
  }

  function _baseURI() internal view override returns (string memory) {
    return _nftBaseURI;
  }

  function getBaseURI() public view returns (string memory) {
    return _nftBaseURI;
  }

  function updateBaseURI(string memory newBaseURI) public onlyOwner {
    _nftBaseURI = newBaseURI;
    emit BaseURIUpdate(newBaseURI);
  }

  function batchTransfer(address to, uint256[] memory tokenIDs) public {
    for (uint256 i = 0; i < tokenIDs.length; i ++) {
      _transfer(msg.sender, to, tokenIDs[i]);
    }
  }

  function batchBurn(uint256[] memory tokenIDs) public {
    for (uint256 i = 0; i < tokenIDs.length; i ++) {
      _burn(tokenIDs[i]);
    }
  }

  function addDnaToSet(uint64 setID, uint64 dnaID) public onlyOwner {
    require(dnaID < _state.nextDnaID, "DNA doesn't exist.");
    require(setID < _state.nextSetID, "Set doesn't exist.");
    require(!_sets[setID].locked, "The set has been locked.");
    require(_sets[setID].added[dnaID] == false, "The dna has already been added to the set.");

    _sets[setID].dnas.push(dnaID);
    _sets[setID].retired[dnaID] = false;
    _sets[setID].added[dnaID] = true;
    emit DnaAddedToSet(setID, dnaID);
  }

  function addDnasToSet(uint64 setID, uint64[] memory dnaIDs) public onlyOwner {
    for (uint256 i = 0; i < dnaIDs.length; i++) {
      addDnaToSet(setID, dnaIDs[i]);
    }
  }

  function retireDnaFromSet(uint64 setID, uint64 dnaID) public onlyOwner {
    require(setID < _state.nextSetID, "Set doesn't exist.");

    if (!_sets[setID].retired[dnaID]) {
      _sets[setID].retired[dnaID] = true;
      emit DnaRetiredFromSet(setID, dnaID, _sets[setID].minted[dnaID]);
    }
  }

  function retireAllFromSet(uint64 setID) public onlyOwner {
    require(setID < _state.nextSetID, "Set doesn't exist.");
    for (uint256 i = 0; i < _sets[setID].dnas.length; i++) {
      retireDnaFromSet(setID, _sets[setID].dnas[i]);
    }
  }

  function lockSet(uint64 setID) public onlyOwner {
    require(setID < _state.nextSetID, "Set doesn't exist.");

    if (!_sets[setID].locked) {
      _sets[setID].locked = true;
      emit SetLocked(setID);
    }
  }

  function cloning(uint64 setID, uint64 dnaID) public payable {
    require(setID < _state.nextSetID, "Set doesn't exist.");
    require(dnaID < _state.nextDnaID, "DNA doesn't exist.");
    require(!_sets[setID].retired[dnaID], "DNA has been retired.");
    require(msg.value >= 0.01 ether, "Clone Fee is 0.01 ether per Yaklone.");

    _sets[setID].minted[dnaID] += 1;
    uint256 serialID = _sets[setID].minted[dnaID];
    uint256 tokenID = _state.nextYaklonID;
    _state.nextYaklonID += 1;
    _nfts[tokenID].tokenID = tokenID;
    _nfts[tokenID].dnaID = dnaID;
    _nfts[tokenID].setID = setID;
    _nfts[tokenID].serialID = serialID;
    _safeMint(msg.sender, tokenID);
    emit YaklonMinted(tokenID, dnaID, setID, serialID);
  }

  function batchCloning(uint64 setID, uint64 dnaID, uint32 amount) public payable {
    require(msg.value >= 0.01 ether * amount, "Clone Fee is 0.01 ether per Yaklone.");

    for (uint32 i = 0; i < amount; i++) {
      cloning(setID, dnaID);
    }
  }

  function createDna(string memory metadata) public onlyOwner returns (uint64) {
    require(bytes(metadata).length > 0, "Metadata doesn't been null.");
    uint64 newID = _state.nextDnaID;
    _state.nextDnaID += 1;
    _dnas[newID].dnaID = newID;
    _dnas[newID].metadata = metadata;
    emit DnaCreated(newID);
    return newID;
  }

  function createSet(string memory name) public onlyOwner returns (uint64) {
    require(bytes(name).length > 0, "Name doesn't been null.");

    uint64 newID = _state.nextSetID;
    _state.nextSetID += 1;
    _sets[newID].setID = newID;
    _sets[newID].name = name;
    _sets[newID].series = _state.currentSeries;
    emit SetCreated(_state.nextSetID, _state.currentSeries);
    return newID;
  }

  function startNewSeries() public onlyOwner returns (uint64) {
    _state.currentSeries += 1;
    emit NewSeriesStarted(_state.currentSeries);

    return _state.currentSeries;
  }

  function withdraw(uint256 amount) public onlyOwner payable {
    require(amount <= address(this).balance, "The contract's balance is running low.");
    payable(msg.sender).transfer(amount);
    emit Withdraw(msg.sender, amount);
  }

  function getDnaData(uint64 dnaID) public view returns (string memory metadata) {
    require(dnaID < _state.nextDnaID, "DNA doesn't exist.");
    return _dnas[dnaID].metadata;
  }

  function getSetData(uint64 setID) public view returns (string memory name, uint64 series, bool locked) {
    require(setID < _state.nextSetID, "Set doesn't exist.");
    return (_sets[setID].name, _sets[setID].series, _sets[setID].locked);
  }

  function getDnasInSet(uint64 setID) public view returns (uint64[] memory) {
    require(setID < _state.nextSetID, "Set doesn't exist.");
    return _sets[setID].dnas;
  }

  function getDnaMintedInSet(uint64 setID, uint64 dnaID) public view returns (uint256) {
    return _sets[setID].minted[dnaID];
  }

  function getNftMetadata(uint256 tokenID) public view returns (uint256 serialID, uint256 feed, uint64 dnaID, uint64 setID) {
    return (_nfts[tokenID].serialID, _nfts[tokenID].feed, _nfts[tokenID].dnaID, _nfts[tokenID].setID);
  }

  function getState() public view returns (uint64 currentSeries, uint64 nextDnaID, uint64 nextSetID, uint256 nextCloneID) {
    return (_state.currentSeries, _state.nextDnaID, _state.nextSetID, _state.nextYaklonID);
  }

  function feeding(uint256 tokenID, uint256 amount) public {
    require(YakYakRewards(_token).balanceOf(msg.sender) >= amount, "Your balance is running low.");
    YakYakRewards(_token).burnFrom(msg.sender, amount);
    _nfts[tokenID].feed += amount;
    emit YaklonFed(tokenID, amount);
  }

  function getSeriesSet(uint64 seriesID) public view returns (uint64[] memory) {
    require(seriesID <= _state.currentSeries, "The seriesID is not exist.");

    uint64[] memory setsList = new uint64[](_state.nextSetID);
    uint64 i = 0;
    uint64 setID = 0;
    while (setID < _state.nextSetID) {
      if (_sets[setID].series == seriesID){
        setsList[i] = setID;
        i++;
      }
      setID++;
    }

    return setsList;
  }
}