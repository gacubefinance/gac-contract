// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract Base {
    address public admin;
    // auth account
    mapping(address => bool) public auth;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "onlyAdmin");
        _;
    }

    modifier onlyAuth() {
        require(auth[msg.sender], "onlyAuth");
        _;
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    function setAuth(address _account, bool _authState) external onlyAdmin {
        require(auth[_account] != _authState, "setAuth: auth[_account] != _authState");
        auth[_account] = _authState;
    }

}

contract GACToken is ERC20, Base {
    uint public constant MAX_SUPPLY = 1_000_000_000;

    constructor() ERC20("GACUBE", "GAC") {
        _mint(msg.sender, 200_000_000 * 10 ** decimals());
    }

    function mint(address _to, uint _amount) external onlyAuth {
        _mint(_to, _amount);
    }

    function _mint(address account, uint256 amount) internal override {
        super._mint(account, amount);
        require(MAX_SUPPLY >= totalSupply(), "_mint: MAX_SUPPLY >= totalSupply()");
    }

}
