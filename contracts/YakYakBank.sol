// SPDX-License-Identifier: MIT
// The organizer will remit the tokens into the prize cashing pool, and issue the prize cashing code signed by owner offline.
// The winner can cash the prize by himself in the contract.
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IYakYakBank {
    // cash cheque order
    struct ORDER {
        uint256 amount;
        address casher;
    }

    // The cheque
    struct CHEQUE {
        uint256 id;
        uint256 amount;
    }

    event Withdraw(address indexed account, uint256 amount);
    event Deposit(address indexed account, uint256 amount);
    event Cash(address indexed from, uint256 id, uint256 amount, address indexed casher);

    // Get the balance of account
    function balanceOf(address account) external view returns (uint256);
    // Deposit token into contract
    function deposit(uint256 amount) external;
    // Withdraw token from contract
    function withdraw(address to, uint256 amount) external;
    // Get the cashing cheque
    function getOrder(address account, uint256 id) external view returns (ORDER memory);
    // Verify cheque
    function verify(CHEQUE memory cheque, bytes32 r, bytes32 s, uint8 v) external view returns (address);
    // Cash cheque
    function cash(CHEQUE memory cheque, bytes32 r, bytes32 s, uint8 v) external;
}

contract YakYakBank is IYakYakBank {
    // The token to be cashed
    ERC20 public _token;

    // Used to EIP712 domain
    uint256 _chainid;

    constructor (address tokenAddress_) {
        _token = ERC20(tokenAddress_);
        _chainid = block.chainid;
    }

    // Map of all users' balance
    mapping(address => uint256) _ledger;

    // Get the balance of account
    function balanceOf(address account) public override view returns (uint256) {
        return _ledger[account];
    }

    // Deposit token into contract
    function deposit(uint256 amount) public override {
        require(amount <= _token.balanceOf(msg.sender), "Bank: Sorry, your balance is running low!");
        _token.transferFrom(msg.sender, address(this), amount);
        _ledger[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    // Withdraw token from user's balance
    function withdraw(address to, uint256 amount) public override {
        require(amount <= _ledger[msg.sender], "Bank: Sorry, your balance is running low!");
        _ledger[msg.sender] -= amount;
        _token.transfer(to, amount);
        emit Withdraw(msg.sender, amount);
    }

    // Map of all users' cashing cheque orders
    mapping(address => mapping(uint256 => ORDER)) _orders;

    // Get the cashing cheque order
    function getOrder(address account, uint256 id) public override view returns (ORDER memory) {
        return _orders[account][id];
    }

    // Hash cheque
    function hashCheque(CHEQUE memory cheque) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
                "\x19\x01",
                keccak256(abi.encode(
                    keccak256(
                        abi.encode("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    ),
                    keccak256(abi.encode("YakYak Bank")),
                    keccak256(abi.encode("1")),
                    _chainid,
                    address(this)
                )),
                keccak256(abi.encode(
                    keccak256(abi.encode("Cheque(uint256 id, uint256 amount)")),
                    cheque.id,
                    cheque.amount
                ))
            ));
    }

    // Verify cheque
    function verify(CHEQUE memory cheque, bytes32 r, bytes32 s, uint8 v) public override view returns (address) {
        return ecrecover(hashCheque(cheque), v, r, s);
    }

    // Cash cheque
    function cash(CHEQUE memory cheque, bytes32 r, bytes32 s, uint8 v) public override {
        address signer = verify(cheque, r, s, v);
        require(cheque.amount <= _ledger[signer], "Bank: Sorry, this is a dishonored check!");
        require(_orders[signer][cheque.id].casher == address(0), "Bank: Sorry, this check is void!");
        _ledger[signer] -= cheque.amount;
        _orders[signer][cheque.id] = ORDER(cheque.amount, msg.sender);
        _token.transfer(msg.sender, cheque.amount);
        emit Cash(signer, cheque.id, cheque.amount, msg.sender);
    }
}
