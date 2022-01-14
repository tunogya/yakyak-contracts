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
    _nextPeriodID = 0;
    _nextCloneID = 0;
    _token = ERC20(tokenAddress_);
  }

  event DNACreated(uint256 indexed id);
  event NewSeriesStarted(uint256 indexed new_currentSeries);
  event PeriodCreated(uint256 indexed periodID, uint256 indexed series);
  event DNAAddedToPeriod(uint256 indexed periodID, uint256 indexed dnaID);
  event DNARetiredFromPeriod(uint256 indexed periodID, uint256 indexed dnaID, uint256 numClones);
  event PeriodLocked(uint256 indexed periodID);
  event YaklonCloned(uint256 indexed cloneID, uint256 indexed dnaID, uint256 indexed periodID, uint256 serialNumber);
  event YaklonDestroyed(uint256 indexed id);
  event Withdraw(address indexed account, uint256 amount);
  event WithdrawToken(address indexed account, uint256 amount);

  uint256 private _currentSeries;
  mapping(uint256 => DNA) private _dnas;
  mapping(uint256 => Period) private _periods;
  mapping(uint256 => Yaklon) private _yaklons;
  uint256 private _nextDNAID;
  uint256 private _nextPeriodID;
  uint256 private _nextCloneID;

  struct Yaklon {
    uint256 cloneID;
    uint256 dnaID;
    uint256 periodID;
    uint256 serialNumber;
    uint256 from;
    uint256 weight;
    string metadata;
  }

  struct DNA {
    uint256 dnaID;
    uint256 scale;
    uint8 level;
    string metadata;
  }

  struct Period {
    uint256 periodID;
    string name;
    uint256 start;
    uint256 end;
    uint256 series;
    uint256[] dnas;
    mapping(uint256 => bool) retired;
    mapping(uint256 => bool) added;
    bool locked;
    mapping(uint256 => uint256) numberMintedPerDNA;
  }

  function totalSupply() public view returns (uint256) {
    return _nextCloneID;
  }

  function transfer(address to, uint256 cloneID) public returns (bool) {
    _safeTransfer(msg.sender, to, cloneID, "");
    return true;
  }

  function batchTransfer(address to, uint256[] memory cloneIDs) public {
    for (uint256 i = 0; i < cloneIDs.length; i ++) {
      transfer(to, cloneIDs[i]);
    }
  }

  function batchBurn(uint256[] memory cloneIDs) public {
    for (uint256 i = 0; i < cloneIDs.length; i ++) {
      _burn(cloneIDs[i]);
    }
  }

  function addDNAToPeriod(uint256 periodID, uint256 dnaID) public onlyOwner {
    require(dnaID < _nextDNAID, "Cannot add the dna to Period: DNA doesn't exist.");
    require(periodID < _nextPeriodID, "Cannot add the dna to Period: Period doesn't exist.");
    require(!_periods[periodID].locked, "Cannot add the dna to the Period after the period has been locked.");
    require(_periods[periodID].added[dnaID] == false, "Cannot add the dna to Period: The dna has already been added to the period.");

    Period storage period = _periods[periodID];
    period.dnas.push(dnaID);
    period.retired[dnaID] = false;
    period.added[dnaID] = true;
    emit DNAAddedToPeriod(periodID, dnaID);
  }

  function addDNAsToPeriod(uint256 periodID, uint256[] memory dnaIDs) public onlyOwner {
    for (uint256 i = 0; i < dnaIDs.length; i++) {
      addDNAToPeriod(periodID, dnaIDs[i]);
    }
  }

  function retireDNAFromPeriod(uint256 periodID, uint256 dnaID) public onlyOwner {
    require(periodID < _nextPeriodID, "Cannot add the dna to Period: Period doesn't exist.");

    if (!_periods[periodID].retired[dnaID]) {
      _periods[periodID].retired[dnaID] = true;
      emit DNARetiredFromPeriod(periodID, dnaID, _periods[periodID].numberMintedPerDNA[dnaID]);
    }
  }

  function retireAllFromPeriod(uint256 periodID) public onlyOwner {
    require(periodID < _nextPeriodID, "Cannot add the dna to Period: Period doesn't exist.");
    for (uint256 i = 0; i < _periods[periodID].dnas.length; i++) {
      retireDNAFromPeriod(periodID, _periods[periodID].dnas[i]);
    }
  }

  function lockPeriod(uint256 periodID) public onlyOwner {
    require(periodID < _nextPeriodID, "Cannot add the dna to Period: Period doesn't exist.");

    if (!_periods[periodID].locked) {
      _periods[periodID].locked = true;
      emit PeriodLocked(periodID);
    }
  }

  function rand(uint256 _length, uint256 _nonce) public view returns (uint256) {
    uint256 random = uint256(keccak256(abi.encodePacked(_nextCloneID, msg.sender, _nonce)));
    return random % _length;
  }

  function cloning(uint256 periodID, uint256 dnaID, string memory metadata) public payable {
    require(periodID < _nextPeriodID, "Cannot clone the dna: Period doesn't exist.");
    require(dnaID < _nextDNAID, "Cannot clone the dna: DNA doesn't exist.");
    require(!_periods[periodID].retired[dnaID], "Cannot clone the dna: DNA has been retired.");
    Period storage period = _periods[periodID];
    period.numberMintedPerDNA[dnaID] += 1;
    DNA storage dna = _dnas[dnaID];
    uint256 randomFrom = rand((period.end - period.start), msg.value) + period.start;
    uint256 randomScale = (rand(dna.scale * 2, msg.value) + dna.scale * 9) / 10;
    uint256 cost = randomFrom * randomScale * (10 ** (dna.level - 1));
    require(_token.balanceOf(msg.sender) >= cost, "Cannot clone the dna: Your balance is running low.");
    _token.transferFrom(msg.sender, address(this), cost);
    uint256 serialNumber = period.numberMintedPerDNA[dnaID];
    uint256 cloneID = _nextCloneID;
    Yaklon storage newClone = _yaklons[cloneID];
    newClone.cloneID = cloneID;
    newClone.dnaID = dnaID;
    newClone.periodID = periodID;
    newClone.from = randomFrom;
    newClone.weight = randomScale;
    newClone.serialNumber = serialNumber;
    newClone.metadata = metadata;
    _safeMint(msg.sender, cloneID);
    emit YaklonCloned(cloneID, dnaID, periodID, serialNumber);
    _nextCloneID += 1;
  }

  function createDNA(string memory metadata, uint256 weight, uint8 level) public onlyOwner returns (uint256) {
    require(bytes(metadata).length > 0, "Cannot create this dna: Metadata doesn't been null.");
    uint256 newID = _nextDNAID;
    DNA storage newDNA = _dnas[newID];
    newDNA.dnaID = newID;
    newDNA.metadata = metadata;
    newDNA.scale = weight;
    newDNA.level = level;
    emit DNACreated(newID);
    _nextDNAID += 1;
    return newID;
  }

  function createPeriod(string memory name, uint256 start, uint256 end) public onlyOwner returns (uint256) {
    require(bytes(name).length > 0, "Cannot create this period: Name doesn't been null.");
    require(end > start, "Cannot create this period: end should greater than start.");

    uint256 newID = _nextPeriodID;
    Period storage newPeriod = _periods[newID];
    newPeriod.periodID = _nextPeriodID;
    newPeriod.name = name;
    newPeriod.start = start;
    newPeriod.end = end;
    newPeriod.series = _currentSeries;
    emit PeriodCreated(_nextPeriodID, _currentSeries);
    _nextPeriodID += 1;
    return newID;
  }

  function startNewSeries() public onlyOwner returns (uint256) {
    _currentSeries += 1;
    emit NewSeriesStarted(_currentSeries);

    return _currentSeries;
  }

  function withdraw(uint256 amount) public onlyOwner payable {
    require(amount <= address(this).balance, "Sorry, the balance is running low!");
    payable(msg.sender).transfer(amount);
    emit Withdraw(msg.sender, amount);
  }

  function withdrawToken(uint256 amount) public onlyOwner {
    require(amount <= _token.balanceOf(address(this)), "Sorry, the balance is running low!");
    _token.transfer(msg.sender, amount);
    emit WithdrawToken(msg.sender, amount);
  }

  function getDNAMetadata(uint256 dnaID) public view returns (string memory) {
    require(dnaID < _nextDNAID, "DNA doesn't exist.");

    return _dnas[dnaID].metadata;
  }

  function tokenURI(uint256 cloneID) public override view returns (string memory) {
    require(cloneID < _nextCloneID, "Yaklon doesn't exist.");

    return _yaklons[cloneID].metadata;
  }

  function getPeriodName(uint256 periodID) public view returns (string memory) {
    require(periodID < _nextPeriodID, "Period doesn't exist.");

    return _periods[periodID].name;
  }

  function getPeriodSeries(uint256 periodID) public view returns (uint256) {
    require(periodID < _nextPeriodID, "Period doesn't exist.");

    return _periods[periodID].series;
  }

  function getDNAsInPeriod(uint256 periodID) public view returns (uint256[] memory) {
    require(periodID < _nextPeriodID, "Period doesn't exist.");

    return _periods[periodID].dnas;
  }

  function isPeriodLocked(uint256 periodID) public view returns (bool) {
    require(periodID < _nextPeriodID, "Period doesn't exist.");

    return _periods[periodID].locked;
  }

  function getNextDNAID() public view returns (uint256) {
    return _nextDNAID;
  }

  function getNextPeriodID() public view returns (uint256) {
    return _nextPeriodID;
  }

  function getCurrentSeries() public view returns (uint256) {
    return _currentSeries;
  }
}