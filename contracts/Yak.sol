// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Yak is ERC721, ERC721Burnable, Ownable {
  constructor() ERC721("Yak", "Yak") {
    _nextPlayID = 1;
    _nextSetID = 1;
  }

  event PlayCreated(uint32 id);
  event NewSeriesStarted(uint32 new_currentSeries);
  event SetCreated(uint32 setID, uint32 series);
  event PlayAddedToSet(uint32 setID, uint32 playID);
  event PlayRetiredFromSet(uint32 setID, uint32 playID, uint32 numMoments);
  event SetLocked(uint32 setID);
  event MomentMinted(uint64 momentID, uint32 playID, uint32 setID, uint32 serialNumber);
  event MomentDestroyed(uint64 id);

  // Series that this Set belongs to.
  // Series is a concept that indicates a group of Sets through time.
  // Many Sets can exist at a time, but only one series.
  uint32 private _currentSeries;

  // Variable size dictionary of Play structs
  mapping(uint32 => Play) private _plays;

  // Variable size dictionary of Set resources
  mapping(uint32 => Set) private _sets;

  // Variable size dictionary of Moment structs
  mapping(uint64 => Moment) private _moments;

  // The ID that is used to create Plays.
  uint32 private _nextPlayID;

  // The ID that is used to create Sets.
  uint32 private _nextSetID;

  // The total number of Yak NFTs that have been created, nextMomentID
  uint64 private _totalSupply;

  struct Moment {
    uint64 momentID;
    uint32 playID;
    uint32 setID;
    uint32 serialNumber;
  }

  struct Play {
    // The unique ID for the Play
    uint32 playID;

    // Stores all the metadata about the play as a string mapping
    mapping(string => string) metadata;
  }

  struct Set {
    // Unique ID for the set
    uint32 setID;

    // Name of the Set
    string name;

    // Series that this Set belongs to.
    uint32 series;

    // Array of _plays that are a part of this set
    uint32[] plays;

    // Map of Play IDs that Indicates if a Play in this Set can be minted.
    // When a Play is added to a Set, it is mapped to false (not retired).
    // When a Play is retired, this is set to true and cannot be changed.
    mapping(uint32 => bool) retired;

    // Indicates if the Set is currently locked.
    // When a Set is created, it is unlocked and Plays are allowed to be added to it.
    // When a set is locked, Plays cannot be added.
    // A Set can never be changed from locked to unlocked, the decision to lock a Set it is final.
    // If a Set is locked, Plays cannot be added, but Moments can still be minted from Plays that exist in the Set.
    bool locked;

    // Mapping of Play IDs that indicates the number of Moments that have been minted for specific Plays in this Set.
    // When a Moment is minted, this value is stored in the Moment to show its place in the Set, eg. 13 of 60.
    mapping(uint32 => uint32) numberMintedPerPlay;
  }

  function _addPlay(uint32 setID, uint32 playID) private {
    require(_plays[playID].playID != 0, "Cannot add the Play to Set: Play doesn't exist.");
    require(!_sets[setID].locked, "Cannot add the play to the Set after the set has been locked.");
    require(_sets[setID].numberMintedPerPlay[playID] == 0, "The play has already been added to the set.");

    _sets[setID].plays.push(playID);
    _sets[setID].retired[playID] = false;
    emit PlayAddedToSet(setID, playID);
  }

  function _addPlays(uint32 setID, uint32[] memory playIDs) private {
    for (uint i = 0; i < playIDs.length; i++) {
      _addPlay(setID, playIDs[i]);
    }
  }

  function _retirePlay(uint32 setID, uint32 playID) private {
    if (!_sets[setID].retired[playID]) {
      _sets[setID].retired[playID] = true;
      emit PlayRetiredFromSet(setID, playID, _sets[setID].numberMintedPerPlay[playID]);
    }
  }

  function _retireAll(uint32 setID) private {
    for (uint i = 0; i < _sets[setID].plays.length; i++) {
      _retirePlay(setID, _sets[setID].plays[i]);
    }
  }

  function _lock(uint32 setID) private {
    if (!_sets[setID].locked) {
      _sets[setID].locked = true;
    }
  }

  function _mintMoment(uint32 setID, uint32 playID) private {
    require(setID <= _nextSetID, "cannot mint the moment from this play: This set doesn't exist.");
    require(playID <= _nextPlayID, "cannot mint the moment from this play: This play doesn't exist.");
    require(!_sets[setID].retired[playID], "cannot mint the moment from this play: This play has been retired.");

    // Gets the number of Moments that have been minted for this Play
    _sets[setID].numberMintedPerPlay[playID] += 1;
    uint32 serialNumber = _sets[setID].numberMintedPerPlay[playID];
    _totalSupply += 1;
    uint64 momentID = _totalSupply;
    Moment memory moment = Moment(momentID, playID, setID, serialNumber);
    _moments[momentID] = moment;

    _safeMint(address(this), momentID);
    emit MomentMinted(momentID, playID, setID, _currentSeries);
  }

  function _batchMintMoment(uint32 setID, uint32 playID, uint64 quantity) private {
    for (uint64 i = 0; i < quantity; i++) {
      _mintMoment(setID, playID);
    }
  }

  function safeMint(uint32 setID, uint32 playID)
  public
  onlyOwner
  {
    _mintMoment(setID, playID);
  }

  function _createPlay(mapping(string => string) storage metadata) private returns (uint32) {
//    Play storage newPlay = Play(_nextPlayID, metadata);
    uint32 newID = _nextPlayID;
//    _plays[newID] = newPlay;
//    emit PlayCreated(newID);
    _nextPlayID += 1;
    return newID;
  }

  function _createSet(string memory name) private returns (uint32) {
//    Set storage newSet;
//    newSet.setID = _nextSetID;
    uint32 newID = _nextSetID;
//    newSet.name = name;
//    newSet.series = _currentSeries;
//    _sets[_nextSetID] = newSet;
//    emit SetCreated(newSet.setID, newSet.series);

    _nextSetID += 1;
    return newID;
  }

  function _startNewSeries() private returns (uint32) {
    _currentSeries += 1;
    emit NewSeriesStarted(_currentSeries);

    return _currentSeries;
  }

//  function getAllPlays() public view returns (Play[] storage) {
//    // todo
//    return;
//  }

//  function getPlayMetaData(uint32 playID) public view returns (mapping(string => string) storage) {
//    return _plays[playID].metadata;
//  }

  function getSetName(uint32 setID) public view returns (string memory) {
    return _sets[setID].name;
  }

  function getSetSeries(uint32 setID) public view returns (uint32) {
    return _sets[setID].series;
  }

  function getPlaysInSet(uint32 setID) public view returns (uint32[] memory) {
    return _sets[setID].plays;
  }

  function isSetLocked(uint32 setID) public view returns (bool) {
    return _sets[setID].locked;
  }
}