// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Clone is ERC721, ERC721Burnable, Ownable {
  constructor() ERC721("Clone", "Clone") {
    _nextBlueprintID = 0;
    _nextSetID = 0;
    _nextCloneID = 0;
  }

  event BlueprintCreated(uint32 id);
  event NewSeriesStarted(uint32 new_currentSeries);
  event SetCreated(uint32 setID, uint32 series);
  event BlueprintAddedToSet(uint32 setID, uint32 blueprintID);
  event BlueprintRetiredFromSet(uint32 setID, uint32 playID, uint32 numClones);
  event SetLocked(uint32 setID);
  event CloneMinted(uint64 cloneID, uint32 blueprintID, uint32 setID, uint32 serialNumber);
  event CloneDestroyed(uint64 id);

  uint32 private _currentSeries;
  mapping(uint32 => Blueprint) private _blueprints;
  mapping(uint32 => Set) private _sets;
  mapping(uint64 => CloneData) private _clones;
  uint32 private _nextBlueprintID;
  uint32 private _nextSetID;
  uint64 private _nextCloneID;

  struct CloneData {
    uint64 cloneID;
    uint32 blueprintID;
    uint32 setID;
    uint32 serialNumber;
  }

  struct Blueprint {
    uint32 blueprintID;
    string metadata;
  }

  struct Set {
    uint32 setID;
    string name;
    uint32 series;
    uint32[] blueprints;
    mapping(uint32 => bool) retired;
    mapping(uint32 => bool) added;
    bool locked;
    mapping(uint32 => uint32) numberMintedPerBlueprint;
  }

  function addBlueprintToSet(uint32 setID, uint32 blueprintID) public onlyOwner {
    require(blueprintID < _nextBlueprintID, "Cannot add the blueprint to Set: Blueprint doesn't exist.");
    require(setID < _nextSetID, "Cannot add the blueprint to Set: Set doesn't exist.");
    require(!_sets[setID].locked, "Cannot add the blueprint to the Set after the set has been locked.");
    require(_sets[setID].added[blueprintID] == false, "Cannot add the blueprint to Set: The blueprint has already been added to the set.");

    Set storage set = _sets[setID];
    set.blueprints.push(blueprintID);
    set.retired[blueprintID] = false;
    set.added[blueprintID] = true;
    emit BlueprintAddedToSet(setID, blueprintID);
  }

  function addBlueprintsToSet(uint32 setID, uint32[] memory blueprintIDs) public onlyOwner {
    for (uint i = 0; i < blueprintIDs.length; i++) {
      addBlueprintToSet(setID, blueprintIDs[i]);
    }
  }

  function retireBlueprintFromSet(uint32 setID, uint32 blueprintID) public onlyOwner {
    require(setID < _nextSetID, "Cannot add the blueprint to Set: Set doesn't exist.");

    if (!_sets[setID].retired[blueprintID]) {
      _sets[setID].retired[blueprintID] = true;
      emit BlueprintRetiredFromSet(setID, blueprintID, _sets[setID].numberMintedPerBlueprint[blueprintID]);
    }
  }

  function retireAllFromSet(uint32 setID) public onlyOwner {
    require(setID < _nextSetID, "Cannot add the blueprint to Set: Set doesn't exist.");
    for (uint i = 0; i < _sets[setID].blueprints.length; i++) {
      retireBlueprintFromSet(setID, _sets[setID].blueprints[i]);
    }
  }

  function lockSet(uint32 setID) public onlyOwner {
    require(setID < _nextSetID, "Cannot add the blueprint to Set: Set doesn't exist.");

    if (!_sets[setID].locked) {
      _sets[setID].locked = true;
      emit SetLocked(setID);
    }
  }

  function mintClone(uint32 setID, uint32 blueprintID) public onlyOwner {
    require(setID < _nextSetID, "Cannot mint the clone from this yak: Set doesn't exist.");
    require(blueprintID < _nextBlueprintID, "Cannot mint the clone from this blueprint: Blueprint doesn't exist.");
    require(!_sets[setID].retired[blueprintID], "Cannot mint the clone from this yak: Blueprint has been retired.");

    Set storage set = _sets[setID];
    set.numberMintedPerBlueprint[blueprintID] += 1;
    uint32 serialNumber = set.numberMintedPerBlueprint[blueprintID];
    uint64 cloneID = _nextCloneID;
    CloneData storage newClone = _clones[cloneID];
    newClone.cloneID = cloneID;
    newClone.blueprintID = blueprintID;
    newClone.setID = setID;
    newClone.serialNumber = serialNumber;
    _safeMint(address(this), cloneID);
    emit CloneMinted(cloneID, blueprintID, setID, serialNumber);
    _nextCloneID += 1;
  }

  function batchMintClones(uint32 setID, uint32 blueprintID, uint64 quantity) public onlyOwner {
    require(setID < _nextSetID, "Cannot mint the clone from this blueprint: Set doesn't exist.");
    require(blueprintID < _nextBlueprintID, "Cannot mint the clone from this blueprint: Blueprint doesn't exist.");
    require(quantity > 0, "Cannot mint the clone from this blueprint: Quantity doesn't been 0.");

    for (uint64 i = 0; i < quantity; i++) {
      mintClone(setID, blueprintID);
    }
  }

  function createBlueprint(string memory metadata) public onlyOwner returns (uint32) {
    require(bytes(metadata).length > 0, "Cannot create this blueprint: Metadata doesn't been null.");

    uint32 newID = _nextBlueprintID;
    Blueprint storage newBlueprint = _blueprints[newID];
    newBlueprint.blueprintID = newID;
    newBlueprint.metadata = metadata;
    emit BlueprintCreated(newID);
    _nextBlueprintID += 1;
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

  function getBlueprintMetaData(uint32 blueprintID) public view returns (string memory) {
    require(blueprintID < _nextBlueprintID, "Blueprint doesn't exist.");

    return _blueprints[blueprintID].metadata;
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

  function getBlueprintsInSet(uint32 setID) public view returns (uint32[] memory) {
    require(setID < _nextSetID, "Set doesn't exist.");

    return _sets[setID].blueprints;
  }

  function isSetLocked(uint32 setID) public view returns (bool) {
    require(setID < _nextSetID, "Set doesn't exist.");

    return _sets[setID].locked;
  }

  function getNextBlueprintID() public view returns (uint32) {
    return _nextBlueprintID;
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