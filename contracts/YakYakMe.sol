// SPDX-License-Identifier: MIT
// The organizer will remit the tokens into the prize cashing pool, and issue the prize cashing code signed by owner offline.
// The winner can cash the prize by himself in the contract.
pragma solidity ^0.8.2;

contract YakYakMe {
  mapping(address => bytes32) private _names;
  mapping(bytes32 => address) private _addresses;

  event Take(address indexed account, bytes32 indexed name);
  event Update(address indexed account, bytes32 indexed name);

  function take(bytes32 nameBytes) public {
    require(_names[msg.sender] == 0, "YakYakMe: your already has a username!");
    require(_addresses[nameBytes] == address(0), "YakYakMe: this username has used by others!");
    _names[msg.sender] = nameBytes;
    _addresses[nameBytes] = msg.sender;
    emit Take(msg.sender, nameBytes);
  }

  function update(bytes32 nameBytes) public {
    require(_names[msg.sender] != 0, "YakYakMe: you has no username");
    require(_addresses[_names[msg.sender]] == msg.sender, "YakYakMe: this isn't your username!");
    _addresses[_names[msg.sender]] = address(0);
    _names[msg.sender] = nameBytes;
    _addresses[nameBytes] = msg.sender;
    emit Update(msg.sender, nameBytes);
  }

  function nameToAddress(bytes32 name) public view returns (address) {
    return _addresses[name];
  }

  function addressToName(address account) public view returns (bytes32) {
    return _names[account];
  }


}
