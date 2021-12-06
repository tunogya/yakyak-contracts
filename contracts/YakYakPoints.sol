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

    struct EXCHANGE_ORDER {
        string _ciphertext;     // The ciphertext need to be verified;
        uint256 _amount;        // The amount of Yak Yak Points;
        address _exchanger;     // If had exchanged, will record the exchanger;
    }

    mapping(uint256=>EXCHANGE_ORDER) _exchangeOrder;

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

    function newExchangeOrder(uint256 orderId, string memory ciphertext, uint256 amount) public onlyOwner {
        require(_exchangeOrder[orderId]._ciphertext == "", "Yak: this id had record!");
        _exchangeOrder[orderId]._ciphertext = ciphertext;
        _exchangeOrder[orderId]._amount = amount;
    }
}
