// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract YakYakClone is ERC721, ERC721Burnable, Ownable {
  ERC20 private _token;

  constructor(address tokenAddress_) ERC721("Yaklon", "YAKLON") {
    _nextDNAID = 0;
    _nextSetID = 0;
    _nextCloneID = 0;
    _token = ERC20(tokenAddress_);
  }

  event DNACreated(uint32 indexed id);
  event NewSeriesStarted(uint32 indexed new_currentSeries);
  event SetCreated(uint32 indexed setID, uint32 indexed series);
  event DNAAddedToSet(uint32 indexed setID, uint32 indexed dnaID);
  event DNARetiredFromSet(uint32 indexed setID, uint32 indexed dnaID, uint32 numClones);
  event SetLocked(uint32 indexed setID);
  event YaklonCloned(uint64 indexed cloneID, uint32 indexed dnaID, uint32 indexed setID, uint32 serialNumber);
  event YaklonDestroyed(uint64 indexed id);
  event Withdraw(address indexed account, uint256 amount);

  uint32 private _currentSeries;
  mapping(uint32 => DNA) private _dnas;
  mapping(uint32 => Set) private _sets;
  mapping(uint64 => Yaklon) private _yaklons;
  uint32 private _nextDNAID;
  uint32 private _nextSetID;
  uint64 private _nextCloneID;

  struct Yaklon {
    uint64 cloneID;
    uint32 dnaID;
    uint32 setID;
    uint32 serialNumber;
  }

  struct DNA {
    uint32 dnaID;
    string metadata;
    uint256 fee;
  }

  struct Set {
    uint32 setID;
    string name;
    uint32 series;
    uint32[] dnas;
    mapping(uint32 => bool) retired;
    mapping(uint32 => bool) added;
    bool locked;
    mapping(uint32 => uint32) numberMintedPerDNA;
  }

  function totalSupply() public view returns (uint256) {
    return _nextCloneID;
  }

  function addDNAToSet(uint32 setID, uint32 dnaID) public onlyOwner {
    require(dnaID < _nextDNAID, "Cannot add the dna to Set: DNA doesn't exist.");
    require(setID < _nextSetID, "Cannot add the dna to Set: Set doesn't exist.");
    require(!_sets[setID].locked, "Cannot add the dna to the Set after the set has been locked.");
    require(_sets[setID].added[dnaID] == false, "Cannot add the dna to Set: The dna has already been added to the set.");

    Set storage set = _sets[setID];
    set.dnas.push(dnaID);
    set.retired[dnaID] = false;
    set.added[dnaID] = true;
    emit DNAAddedToSet(setID, dnaID);
  }

  function addDNAsToSet(uint32 setID, uint32[] memory dnaIDs) public onlyOwner {
    for (uint i = 0; i < dnaIDs.length; i++) {
      addDNAToSet(setID, dnaIDs[i]);
    }
  }

  function retireDNAFromSet(uint32 setID, uint32 dnaID) public onlyOwner {
    require(setID < _nextSetID, "Cannot add the dna to Set: Set doesn't exist.");

    if (!_sets[setID].retired[dnaID]) {
      _sets[setID].retired[dnaID] = true;
      emit DNARetiredFromSet(setID, dnaID, _sets[setID].numberMintedPerDNA[dnaID]);
    }
  }

  function retireAllFromSet(uint32 setID) public onlyOwner {
    require(setID < _nextSetID, "Cannot add the dna to Set: Set doesn't exist.");
    for (uint i = 0; i < _sets[setID].dnas.length; i++) {
      retireDNAFromSet(setID, _sets[setID].dnas[i]);
    }
  }

  function lockSet(uint32 setID) public onlyOwner {
    require(setID < _nextSetID, "Cannot add the dna to Set: Set doesn't exist.");

    if (!_sets[setID].locked) {
      _sets[setID].locked = true;
      emit SetLocked(setID);
    }
  }

  function cloning(uint32 setID, uint32 dnaID) public {
    require(setID < _nextSetID, "Cannot clone the dna: Set doesn't exist.");
    require(dnaID < _nextDNAID, "Cannot clone the dna: DNA doesn't exist.");
    require(!_sets[setID].retired[dnaID], "Cannot clone the dna: DNA has been retired.");
    require(_token.balanceOf(msg.sender) >= _dnas[dnaID].fee, "Cannot clone the dna: Your balance is running low.");

    _token.transferFrom(msg.sender, address(this), _dnas[dnaID].fee);

    Set storage set = _sets[setID];
    set.numberMintedPerDNA[dnaID] += 1;
    uint32 serialNumber = set.numberMintedPerDNA[dnaID];
    uint64 cloneID = _nextCloneID;
    Yaklon storage newClone = _yaklons[cloneID];
    newClone.cloneID = cloneID;
    newClone.dnaID = dnaID;
    newClone.setID = setID;
    newClone.serialNumber = serialNumber;
    _safeMint(msg.sender, cloneID);
    emit YaklonCloned(cloneID, dnaID, setID, serialNumber);
    _nextCloneID += 1;
  }

  function batchCloning(uint32 setID, uint32 dnaID, uint64 quantity) public onlyOwner {
    require(setID < _nextSetID, "Cannot mint the clone from this dna: Set doesn't exist.");
    require(dnaID < _nextDNAID, "Cannot mint the clone from this dna: DNA doesn't exist.");
    require(quantity > 0, "Cannot mint the clone from this dna: Quantity doesn't been 0.");

    for (uint64 i = 0; i < quantity; i++) {
      cloning(setID, dnaID);
    }
  }

  function createDNA(string memory metadata, uint256 fee) public onlyOwner returns (uint32) {
    require(bytes(metadata).length > 0, "Cannot create this dna: Metadata doesn't been null.");

    uint32 newID = _nextDNAID;
    DNA storage newDNA = _dnas[newID];
    newDNA.dnaID = newID;
    newDNA.metadata = metadata;
    newDNA.fee = fee;
    emit DNACreated(newID);
    _nextDNAID += 1;
    return newID;
  }

  function createSet(string memory name) public onlyOwner returns (uint32) {
    require(bytes(name).length > 0, "Cannot create this set: Name doesn't been null.");

    uint32 newID = _nextSetID;
    Set storage newSet = _sets[newID];
    newSet.setID = _nextSetID;
    newSet.name = name;
    newSet.series = _currentSeries;
    emit SetCreated(_nextSetID, _currentSeries);
    _nextSetID += 1;
    return newID;
  }

  function startNewSeries() public onlyOwner returns (uint32) {
    _currentSeries += 1;
    emit NewSeriesStarted(_currentSeries);

    return _currentSeries;
  }

  function withdraw(address to, uint256 amount) public onlyOwner {
    require(amount <= _token.balanceOf(address(this)), "Sorry, the balance is running low!");
    _token.transfer(to, amount);
    emit Withdraw(msg.sender, amount);
  }

  function getDNAMetadata(uint32 dnaID) public view returns (string memory) {
    require(dnaID < _nextDNAID, "DNA doesn't exist.");

    return _dnas[dnaID].metadata;
  }

  function getYaklon(uint64 cloneID) public view returns (Yaklon memory) {
    require(cloneID < _nextCloneID, "Yaklon doesn't exist.");

    return _yaklons[cloneID];
  }

  function getSetName(uint32 setID) public view returns (string memory) {
    require(setID < _nextSetID, "Set doesn't exist.");

    return _sets[setID].name;
  }

  function getSetSeries(uint32 setID) public view returns (uint32) {
    require(setID < _nextSetID, "Set doesn't exist.");

    return _sets[setID].series;
  }

  function getDNAsInSet(uint32 setID) public view returns (uint32[] memory) {
    require(setID < _nextSetID, "Set doesn't exist.");

    return _sets[setID].dnas;
  }

  function isSetLocked(uint32 setID) public view returns (bool) {
    require(setID < _nextSetID, "Set doesn't exist.");

    return _sets[setID].locked;
  }

  function getNextDNAID() public view returns (uint32) {
    return _nextDNAID;
  }

  function getNextSetID() public view returns (uint32) {
    return _nextSetID;
  }

  function getCurrentSeries() public view returns (uint32) {
    return _currentSeries;
  }
}