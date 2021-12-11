// SPDX-License-Identifier: MIT
// The organizer will remit the tokens into the prize cashing pool, and issue the prize cashing code signed by owner offline.
// The winner can cash the prize by himself in the contract.
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IYakYakBank {
    // cashing cheque order
    struct ORDER {
        uint256 amount;
        address casher;
    }

    // The cheque
    struct CHEQUE {
        uint256 id;
        uint256 amount;
    }

    event Withdraw(address account, uint256 amount);
    event Deposit(address account, uint256 amount);

    // Get the balance of account
    function balanceOf(address _account) external view returns (uint256);
    // Get EIP712 domain
    function getEIP712Domain() external view returns(string memory _name, string memory _version, uint256 _chainid, address _verifyingContract, bytes32 _salt);
    // Deposit token into contract
    function deposit(uint256 _amount) external;
    // Withdraw token from contract
    function withdraw(address _to, uint256 _amount) external;
    // Get the cashing cheque
    function getOrder(address _account, uint256 _id) external view returns (ORDER memory);
    // Hash cheque
    function hashCheque(CHEQUE memory _cheque) external view returns (bytes32);
    // Verify cheque
    function verify(CHEQUE memory _cheque, uint256 _signature) external view returns(address);
    // Cashing cheque
    function cashing(CHEQUE memory _cheque, uint256 _signature) external;
}

contract YakYakBank is IYakYakBank {
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

    // Get EIP712 domain
    function getEIP712Domain() public override view returns(string memory _name, string memory _version, uint256 _chainid, address _verifyingContract, bytes32 _salt) {
        _name = name;
        _version = version;
        _chainid = chainid;
        _verifyingContract = verifyingContract;
        _salt = salt;
    }

    // Map of all users' balance
    mapping(address => uint256) ledger;

    // Get the balance of account
    function balanceOf(address _account) public override view returns (uint256) {
        return ledger[_account];
    }

    // Deposit token into contract
    function deposit(uint256 _amount) public override {
        require(_amount <= token.balanceOf(msg.sender), "Bank: Sorry, your balance is running low!");
        token.transfer(address(this), _amount);
        ledger[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw token from user's balance
    function withdraw(address _to, uint256 _amount) public override {
        require(_amount <= ledger[msg.sender], "Bank: Sorry, your balance is running low!");
        ledger[msg.sender] -= _amount;
        token.transferFrom(address(this), _to, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    // Map of all users' cashing cheque orders
    mapping(address => mapping(uint256 => ORDER)) orders;

    // Get the cashing cheque order
    function getOrder(address _account, uint256 _id) public override view returns (ORDER memory) {
        return orders[_account][_id];
    }

    // The typehash of CHEQUE
    bytes32 constant CHEQUE_TYPEHASH = keccak256("CHEQUE(uint256 id, uint256 amount)");

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

    // Hash cheque
    function hashCheque(CHEQUE memory _cheque) public override view returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                CHEQUE_TYPEHASH,
                _cheque.id,
                _cheque.amount
            ))
        ));
    }

    // Verify cheque
    function verify(CHEQUE memory _cheque, uint256 _signature) public override view returns(address) {
        // @Todo encode r, s, v from _signature
        bytes32 r;
        bytes32 s;
        uint8 v;

        return ecrecover(hashCheque(_cheque), v, r, s);
    }

    function cashing(CHEQUE memory _cheque, uint256 _signature) public override{
        address signer = verify(_cheque, _signature);
        require(_cheque.amount <= ledger[signer], "Bank: Sorry, this is a dishonored check!");
    }
}
