// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Yak is ERC721, ERC721Burnable, Ownable {
  constructor() ERC721("Yak", "Yak") {
    _nextPlayID = 0;
    _nextSetID = 0;
    _nextMomentID = 0;
  }

  event PlayCreated(uint32 id);
  event NewSeriesStarted(uint32 new_currentSeries);
  event SetCreated(uint32 setID, uint32 series);
  event PlayAddedToSet(uint32 setID, uint32 playID);
  event PlayRetiredFromSet(uint32 setID, uint32 playID, uint32 numMoments);
  event SetLocked(uint32 setID);
  event MomentMinted(uint64 momentID, uint32 playID, uint32 setID, uint32 serialNumber);
  event MomentDestroyed(uint64 id);

  uint32 private _currentSeries;
  Play[] private _plays;
  mapping(uint32 => Set) private _sets;
  mapping(uint64 => Moment) private _moments;
  uint32 private _nextPlayID;
  uint32 private _nextSetID;
  uint64 private _nextMomentID;

  struct Moment {
    uint64 momentID;
    uint32 playID;
    uint32 setID;
    uint32 serialNumber;
  }

  struct Play {
    uint32 playID;
    string metadata;
  }

  struct Set {
    uint32 setID;
    string name;
    uint32 series;
    uint32[] plays;
    mapping(uint32 => bool) retired;
    mapping(uint32 => bool) added;
    bool locked;
    mapping(uint32 => uint32) numberMintedPerPlay;
  }

  function addPlayToSet(uint32 setID, uint32 playID) public onlyOwner {
    require(playID < _nextPlayID, "Cannot add the Play to Set: Play doesn't exist.");
    require(setID < _nextSetID, "Cannot add the Play to Set: Set doesn't exist.");
    require(!_sets[setID].locked, "Cannot add the play to the Set after the set has been locked.");
    require(_sets[setID].added[playID] == false, "Cannot add the Play to Set: The play has already been added to the set.");

    Set storage set = _sets[setID];
    set.plays.push(playID);
    set.retired[playID] = false;
    set.added[playID] = true;
    emit PlayAddedToSet(setID, playID);
  }

  function addPlaysToSet(uint32 setID, uint32[] memory playIDs) public onlyOwner {
    for (uint i = 0; i < playIDs.length; i++) {
      addPlayToSet(setID, playIDs[i]);
    }
  }

  function retirePlayFromSet(uint32 setID, uint32 playID) public onlyOwner {
    require(setID < _nextSetID, "Cannot add the Play to Set: Set doesn't exist.");

    if (!_sets[setID].retired[playID]) {
      _sets[setID].retired[playID] = true;
      emit PlayRetiredFromSet(setID, playID, _sets[setID].numberMintedPerPlay[playID]);
    }
  }

  function retireAllFromSet(uint32 setID) public onlyOwner {
    require(setID < _nextSetID, "Cannot add the Play to Set: Set doesn't exist.");
    for (uint i = 0; i < _sets[setID].plays.length; i++) {
      retirePlayFromSet(setID, _sets[setID].plays[i]);
    }
  }

  function lockSet(uint32 setID) public onlyOwner {
    require(setID < _nextSetID, "Cannot add the Play to Set: Set doesn't exist.");

    if (!_sets[setID].locked) {
      _sets[setID].locked = true;
      emit SetLocked(setID);
    }
  }

  function mintMoment(uint32 setID, uint32 playID) public onlyOwner {
    require(setID < _nextSetID, "Cannot mint the moment from this play: Set doesn't exist.");
    require(playID < _nextPlayID, "Cannot mint the moment from this play: Play doesn't exist.");
    require(!_sets[setID].retired[playID], "Cannot mint the moment from this play: Play has been retired.");

    Set storage set = _sets[setID];
    set.numberMintedPerPlay[playID] += 1;
    uint32 serialNumber = set.numberMintedPerPlay[playID];
    uint64 momentID = _nextMomentID;
    Moment storage newMoment = _moments[momentID];
    newMoment.momentID = momentID;
    newMoment.playID = playID;
    newMoment.setID = setID;
    newMoment.serialNumber = serialNumber;
    _safeMint(address(this), momentID);
    emit MomentMinted(momentID, playID, setID, serialNumber);
    _nextMomentID += 1;
  }

  function batchMintMoment(uint32 setID, uint32 playID, uint64 quantity) public onlyOwner {
    for (uint64 i = 0; i < quantity; i++) {
      mintMoment(setID, playID);
    }
  }

  function createPlay(string memory metadata) private returns (uint32) {
    uint32 newID = _nextPlayID;
    Play storage newPlay = _plays[newID];
    newPlay.playID = newID;
    newPlay.metadata = metadata;
    emit PlayCreated(newID);
    _nextPlayID += 1;
    return newID;
  }

  function createSet(string memory name) private returns (uint32) {
    uint32 newID = _nextSetID;
    Set storage newSet = _sets[newID];
    newSet.setID = _nextSetID;
    newSet.name = name;
    newSet.series = _currentSeries;
    emit SetCreated(_nextSetID, _currentSeries);
    _nextSetID += 1;
    return newID;
  }

  function startNewSeries() private returns (uint32) {
    _currentSeries += 1;
    emit NewSeriesStarted(_currentSeries);

    return _currentSeries;
  }

  function getAllPlays() public view returns (Play[] memory) {
    return _plays;
  }

  function getPlayMetaData(uint32 playID) public view returns (string memory) {
    require(playID < _nextPlayID, "Play doesn't exist.");

    return _plays[playID].metadata;
  }

  function getMoment(uint64 momentID) public view returns (Moment memory) {
    require(momentID < _nextMomentID, "Moment doesn't exist.");

    return _moments[momentID];
  }

  function getSetName(uint32 setID) public view returns (string memory) {
    require(setID < _nextSetID, "Set doesn't exist.");

    return _sets[setID].name;
  }

  function getSetSeries(uint32 setID) public view returns (uint32) {
    require(setID < _nextSetID, "Set doesn't exist.");

    return _sets[setID].series;
  }

  function getPlaysInSet(uint32 setID) public view returns (uint32[] memory) {
    require(setID < _nextSetID, "Set doesn't exist.");

    return _sets[setID].plays;
  }

  function isSetLocked(uint32 setID) public view returns (bool) {
    require(setID < _nextSetID, "Set doesn't exist.");

    return _sets[setID].locked;
  }

  function getNextPlayID() public view returns (uint32) {
    return _nextPlayID;
  }

  function getNextSetID() public view returns (uint32) {
    return _nextSetID;
  }

  function getNextMomentID() public view returns (uint64) {
    return _nextMomentID;
  }

  function getCurrentSeries() public view returns (uint32) {
    return _currentSeries;
  }
}