// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YakYakClone is ERC721, ERC721Burnable, Ownable {
  constructor() ERC721("YakYakClone", "Clone") {
    _nextDNAID = 0;
    _nextSetID = 0;
    _nextCloneID = 0;
  }

  event DNACreated(uint32 id);
  event NewSeriesStarted(uint32 new_currentSeries);
  event SetCreated(uint32 setID, uint32 series);
  event DNAAddedToSet(uint32 setID, uint32 dnaID);
  event DNARetiredFromSet(uint32 setID, uint32 playID, uint32 numClones);
  event SetLocked(uint32 setID);
  event CloneMinted(uint64 cloneID, uint32 dnaID, uint32 setID, uint32 serialNumber);
  event CloneDestroyed(uint64 id);

  uint32 private _currentSeries;
  mapping(uint32 => DNA) private _dnas;
  mapping(uint32 => Set) private _sets;
  mapping(uint64 => CloneData) private _clones;
  uint32 private _nextDNAID;
  uint32 private _nextSetID;
  uint64 private _nextCloneID;

  struct CloneData {
    uint64 cloneID;
    uint32 dnaID;
    uint32 setID;
    uint32 serialNumber;
  }

  struct DNA {
    uint32 dnaID;
    string metadata;
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

  function mintClone(uint32 setID, uint32 dnaID) public onlyOwner {
    require(setID < _nextSetID, "Cannot mint the clone from this yak: Set doesn't exist.");
    require(dnaID < _nextDNAID, "Cannot mint the clone from this dna: DNA doesn't exist.");
    require(!_sets[setID].retired[dnaID], "Cannot mint the clone from this yak: DNA has been retired.");

    Set storage set = _sets[setID];
    set.numberMintedPerDNA[dnaID] += 1;
    uint32 serialNumber = set.numberMintedPerDNA[dnaID];
    uint64 cloneID = _nextCloneID;
    CloneData storage newClone = _clones[cloneID];
    newClone.cloneID = cloneID;
    newClone.dnaID = dnaID;
    newClone.setID = setID;
    newClone.serialNumber = serialNumber;
    _safeMint(msg.sender, cloneID);
    emit CloneMinted(cloneID, dnaID, setID, serialNumber);
    _nextCloneID += 1;
  }

  function batchMintClones(uint32 setID, uint32 dnaID, uint64 quantity) public onlyOwner {
    require(setID < _nextSetID, "Cannot mint the clone from this dna: Set doesn't exist.");
    require(dnaID < _nextDNAID, "Cannot mint the clone from this dna: DNA doesn't exist.");
    require(quantity > 0, "Cannot mint the clone from this dna: Quantity doesn't been 0.");

    for (uint64 i = 0; i < quantity; i++) {
      mintClone(setID, dnaID);
    }
  }

  function createDNA(string memory metadata) public onlyOwner returns (uint32) {
    require(bytes(metadata).length > 0, "Cannot create this dna: Metadata doesn't been null.");

    uint32 newID = _nextDNAID;
    DNA storage newDNA = _dnas[newID];
    newDNA.dnaID = newID;
    newDNA.metadata = metadata;
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

  function getDNAMetadata(uint32 dnaID) public view returns (string memory) {
    require(dnaID < _nextDNAID, "DNA doesn't exist.");

    return _dnas[dnaID].metadata;
  }

  function getClone(uint64 cloneID) public view returns (CloneData memory) {
    require(cloneID < _nextCloneID, "Clone doesn't exist.");

    return _clones[cloneID];
  }

  function getSetName(uint32 setID) public view returns (string memory) {
    require(setID < _nextSetID, "Set doesn't exist.");

    return _sets[setID].name;
  }

  function getSetSeries(uint32 setID) public view returns (uint32) {
    require(setID < _nextSetID, "Set doesn't exist.");

    return _sets[setID].series;
  }

  function getAllDNAs() public {

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

  function getNextCloneID() public view returns (uint64) {
    return _nextCloneID;
  }

  function getCurrentSeries() public view returns (uint32) {
    return _currentSeries;
  }
}