// SPDX-License-Identifier: MIT
// The organizer will remit the tokens into the prize cashing pool, and issue the prize cashing code signed by owner offline.
// The winner can cash the prize by himself in the contract.
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract YakYakBank {
  event Withdraw(address indexed account, uint256 amount);
  event Deposit(address indexed account, uint256 amount);
  event Cash(address indexed from, uint256 id, uint256 amount, address indexed casher);

  // The token to be cashed
  ERC20 private _token;

  // Used to EIP712 domain
  uint256 private _chainid;

  constructor (address tokenAddress_) {
    _token = ERC20(tokenAddress_);
    _chainid = block.chainid;
  }

  // Map of all users' balance
  mapping(address => uint256) private _ledger;

  // Get the balance of account
  function balanceOf(address account) public view returns (uint256) {
    return _ledger[account];
  }

  // Deposit token into contract
  function deposit(uint256 amount) public {
    require(amount <= _token.balanceOf(msg.sender), "Bank: Sorry, your balance is running low!");
    _token.transferFrom(msg.sender, address(this), amount);
    _ledger[msg.sender] += amount;
    emit Deposit(msg.sender, amount);
  }

  // Withdraw token from user's balance
  function withdraw(address to, uint256 amount) public {
    require(amount <= _ledger[msg.sender], "Bank: Sorry, your balance is running low!");
    _ledger[msg.sender] -= amount;
    _token.transfer(to, amount);
    emit Withdraw(msg.sender, amount);
  }

  struct ORDER {
    uint256 amount;
    address casher;
  }

  // Map of all users' cashing cheque orders
  mapping(address => mapping(uint256 => ORDER)) private _orders;

  // Get the cashing cheque order
  function getOrder(address account, uint256 id) public view returns (ORDER memory) {
    return _orders[account][id];
  }

  // Cash cheque
  function cash(uint8 v, bytes32 r, bytes32 s, address sender, uint256 id, uint256 amount) public {
    bytes32 eip712DomainHash = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("YakYakBank")),
        keccak256(bytes("1")),
        _chainid,
        address(this)
      )
    );
    bytes32 hashCheque = keccak256(
      abi.encode(
        keccak256("cheque(address sender,uint256 id,uint256 amount)"),
        sender,
        id,
        amount
      )
    );
    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashCheque));
    address signer = ecrecover(hash, v, r, s);
    require(signer == sender, "Bank: Sorry, invalid signature!");
    require(signer != address(0), "ECDSA: Sorry, invalid signature!");
    require(amount <= _ledger[signer], "Bank: Sorry, this is a dishonored check!");
    require(_orders[signer][id].casher == address(0), "Bank: Sorry, this check is void!");
    _ledger[signer] -= amount;
    _orders[signer][id] = ORDER(amount, msg.sender);
    _token.transfer(msg.sender, amount);
    emit Cash(signer, id, amount, msg.sender);
  }
}
