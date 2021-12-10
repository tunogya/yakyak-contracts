// SPDX-License-Identifier: MIT
// The organizer will remit the tokens into the prize cashing pool, and issue the prize cashing code signed by owner offline.
// The winner can cash the prize by himself in the contract.
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PrizeCashingPool is Ownable {
    event Withdraw(uint256 amount);

    // The token to be cashed
    ERC20 public token;

    // Used to EIP712 domain
    string public name;
    string public version;
    uint256 public chainid;
    address public verifyingContract;
    bytes32 public salt;

    constructor (address _tokenAddress, string memory _name, string memory _version, address _verifyingContract, bytes32 _salt) {
        token = ERC20(_tokenAddress);
        name = _name;
        version = _version;
        chainid = block.chainid;
        verifyingContract = _verifyingContract;
        salt = _salt;
    }

    // Withdraw token from contract
    function withdraw(address to, uint256 amount) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (amount <= balance){
            token.transferFrom(address(this), to, amount);
            emit Withdraw(amount);
        } else {
            token.transferFrom(address(this), to, balance);
            emit Withdraw(balance);
        }
    }

    // Prize cashing order
    struct PRIZE_CASHING_ORDER {
        uint256 amount;
        address casher;
    }

    // Map of prize cashing orders
    mapping(uint256=>PRIZE_CASHING_ORDER) prizeCashingOrders;

    // Query the prize cashing order
    function queryPrizeCashingOrder(uint256 id) public view returns (PRIZE_CASHING_ORDER memory) {
        return prizeCashingOrders[id];
    }

    // The prize cashing ticket
    struct PRIZE_CASHING_TICKET {
        uint256 id;
        uint256 amount;
    }

    // The typehash of PRIZE_CASHING_TICKET
    bytes32 constant PRIZE_CASHING_TICKET_TYPEHASH = keccak256("PRIZE_CASHING_TICKET(uint256 id, uint256 amount)");

    string public constant EIP712_DOMAIN = "EIP712Domain(string name,string version,uint256 chainId,address,bytes32 salt)";
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encode(EIP712_DOMAIN));

    bytes32 public DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(name),
        keccak256(version),
        chainid,
        verifyingContract,
        salt
    ));

    function hashPrizeCashingInfo(PRIZE_CASHING_TICKET memory _prizeCashingTicket) internal view returns (bytes32 hash) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                PRIZE_CASHING_TICKET_TYPEHASH,
                _prizeCashingTicket.id,
                _prizeCashingTicket.amount
            ))
        ));
    }

    function verify(PRIZE_CASHING_TICKET memory _prizeCashingTicket, uint256 _signature) public view returns(address) {
        // @Todo encode r, s, v from _signature
        bytes32 r;
        bytes32 s;
        uint8 v;

        return ecrecover(hashPrizeCashingInfo(_prizeCashingTicket), v, r, s);
    }
}
