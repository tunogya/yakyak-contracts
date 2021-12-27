// SPDX-License-Identifier: MIT
// The organizer will remit the tokens into the prize cashing pool, and issue the prize cashing code signed by owner offline.
// The winner can cash the prize by himself in the contract.
pragma solidity ^0.8.2;

contract YakYakMe {
    mapping(address => bytes32) public addressToName;
    mapping(bytes32 => address) public nameToAddress;

    event Take(address indexed account, bytes32 indexed name);
    event Update(address indexed account, bytes32 indexed name);

    function take(bytes32 nameBytes) public {
        require(addressToName[msg.sender] == 0, "YakYakMe: your already has a username!");
        require(nameToAddress[nameBytes] == address(0), "YakYakMe: this username has used by others!");
        addressToName[msg.sender] = nameBytes;
        nameToAddress[nameBytes] = msg.sender;
        emit Take(msg.sender, nameBytes);
    }

    function update(bytes32 nameBytes) public {
        require(addressToName[msg.sender] != 0, "YakYakMe: you has no username");
        require(nameToAddress[addressToName[msg.sender]] == msg.sender, "YakYakMe: this isn't your username!");
        nameToAddress[addressToName[msg.sender]] = address(0);
        addressToName[msg.sender] = nameBytes;
        nameToAddress[nameBytes] = msg.sender;
        emit Update(msg.sender, nameBytes);
    }
}
