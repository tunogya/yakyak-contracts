// SPDX-License-Identifier: MIT
// The organizer will remit the tokens into the prize cashing pool, and issue the prize cashing code signed by owner offline.
// The winner can cash the prize by himself in the contract.
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IPrizeCashingPool {
    // Prize cashing order
    struct ORDER {
        uint256 amount;
        address casher;
    }

    // The prize cashing ticket
    struct TICKET {
        uint256 id;
        uint256 amount;
    }

    event Withdraw(uint256 amount);

    // query EIP712 domain
    function queryEIP712Domain() external view returns(string memory _name, string memory _version, uint256 _chainid, address _verifyingContract, bytes32 _salt);
    // Withdraw token from contract
    function withdraw(address _to, uint256 _amount) external;
    // Query the prize cashing order
    function queryOrder(uint256 _id) external view returns (ORDER memory order);
    // hash ticket
    function hashTicket(TICKET memory _ticket) external view returns (bytes32 hash);
    // verify ticket
    function verifyTicket(TICKET memory _ticket, uint256 _signature) external view returns(address);
}

contract PrizeCashingPool is Ownable, IPrizeCashingPool {
    // The token to be cashed
    ERC20 public token;

    // Used to EIP712 domain
    string name;
    string version;
    uint256 chainid;
    address verifyingContract;
    bytes32 salt;

    constructor (address _tokenAddress, string memory _name, string memory _version, bytes32 _salt) {
        token = ERC20(_tokenAddress);
        name = _name;
        version = _version;
        chainid = block.chainid;
        verifyingContract = address(this);
        salt = _salt;
    }

    // query EIP712 domain
    function queryEIP712Domain() public override view returns(string memory _name, string memory _version, uint256 _chainid, address _verifyingContract, bytes32 _salt) {
        return (name, version, chainid, verifyingContract, salt);
    }

    // Withdraw token from contract
    function withdraw(address _to, uint256 _amount) public override onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(_amount <= balance, "Pool: Sorry, pool balance is low!");
        token.transferFrom(address(this), _to, _amount);
        emit Withdraw(_amount);
    }

    // Map of prize cashing orders
    mapping(uint256=> ORDER) orders;

    // Query the prize cashing order
    function queryOrder(uint256 _id) public override view returns (ORDER memory order) {
        return orders[_id];
    }

    // The typehash of PRIZE CASHING TICKET
    bytes32 constant TICKET_TYPEHASH = keccak256("TICKET(uint256 id, uint256 amount)");

    string constant EIP712_DOMAIN = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)";
    bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encode(EIP712_DOMAIN));

    bytes32 public DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(abi.encode(name)),
        keccak256(abi.encode(version)),
        chainid,
        verifyingContract,
        salt
    ));

    // hash ticket
    function hashTicket(TICKET memory _ticket) public override view returns (bytes32 hash) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                TICKET_TYPEHASH,
                _ticket.id,
                _ticket.amount
            ))
        ));
    }

    // verify ticket
    function verifyTicket(TICKET memory _ticket, uint256 _signature) public override view returns(address) {
        // @Todo encode r, s, v from _signature
        bytes32 r;
        bytes32 s;
        uint8 v;

        return ecrecover(hashTicket(_ticket), v, r, s);
    }
}
