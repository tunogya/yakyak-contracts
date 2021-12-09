// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @custom:security-contact tunogya@qq.cn
contract YakYakPoints is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    event ExchangeAward(uint256 id, uint256 amount, address exchanger);

    /// @dev exchange order struct
    struct EXCHANGE_ORDER {
        uint256 amount;        // The amount of Yak Yak Points reward;
        address exchanger;     // If had exchanged, will record the exchanger;
    }

    /// @dev map of exchange order
    mapping(uint256=>EXCHANGE_ORDER) exchangeOrder;

    struct POINTS_AWARD {
        uint256 id;
        uint256 amount;
    }

    function initialize() initializer public {
        __ERC20_init("Yak Yak Points", "Yak");
        __ERC20Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    /// @dev get exchange order info
    function getExchangeOrder(uint256 id) public view returns (EXCHANGE_ORDER memory) {
        require(exchangeOrder[id].exchanger != address(0), "Yak: This id hadn't been exchanged!");
        return exchangeOrder[id];
    }

    uint256 chainId = block.chainid;
    bytes32 constant salt = 0x69eb730727732201433e50655021f58399ca006f718aea66569e0b6317a12669;
    address verifyingContract = address(this);
    string private constant EIP712_DOMAIN = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,address,bytes32 salt)";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encode(EIP712_DOMAIN));
    bytes32 private DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256("Yak Yak Points"),
            keccak256("1"),
            chainId,
            verifyingContract,
            salt
        ));

    bytes32 constant POINTS_AWARD_TYPEHASH = keccak256("POINTS_AWARD(uint256 id, uint256 amount)");

    function _hashPointsAward(POINTS_AWARD memory pointsAward) internal view returns (bytes32 hash) {
        return keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                        POINTS_AWARD_TYPEHASH,
                        pointsAward.id,
                        pointsAward.amount
                    ))
            ));
    }

    function _decode(POINTS_AWARD memory pointsAward, bytes32 sigR, bytes32 sigS, uint8 sigV) internal view returns (address) {
        return ecrecover(_hashPointsAward(pointsAward), sigV, sigR, sigS);
    }

    function exchangeAward(POINTS_AWARD memory pointsAward, bytes32 sigR, bytes32 sigS, uint8 sigV) public {
        require(exchangeOrder[pointsAward.id].exchanger == address(0), "Yak: This award had been exchanged!");
        require(_decode(pointsAward, sigR, sigS, sigV) == owner(), "Yak: This sig is not valid!");

        exchangeOrder[pointsAward.id].amount = pointsAward.amount;
        exchangeOrder[pointsAward.id].exchanger = msg.sender;

        _mint(msg.sender, pointsAward.amount);
        emit ExchangeAward(pointsAward.id, pointsAward.amount, msg.sender);
    }
}
