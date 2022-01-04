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

  uint32 private _currentSeries;
  mapping(uint32 => Play) private _plays;
  mapping(uint32 => Set) private _sets;
  mapping(uint64 => Moment) private _moments;
  uint32 private _nextPlayID;
  uint32 private _nextSetID;
  uint64 private _totalSupply;

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
    bool locked;
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

  function _createPlay(string memory metadata) private returns (uint32) {
    uint32 newID = _nextPlayID;
    _plays[newID].playID = newID;
    _plays[newID].metadata = metadata;
    emit PlayCreated(newID);
    _nextPlayID += 1;
    return newID;
  }

  function _createSet(string memory name) private returns (uint32) {
    uint32 newID = _nextSetID;
    _sets[newID].setID = _nextSetID;
    _sets[newID].name = name;
    _sets[newID].series = _currentSeries;
    emit SetCreated(_nextSetID, _currentSeries);
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

  function getPlayMetaData(uint32 playID) public view returns (string memory) {
    return _plays[playID].metadata;
  }

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