// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BaseUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "hardhat/console.sol";

contract IDO is BaseUpgradeable {
    IERC20Upgradeable public GacToken;
    IERC20Upgradeable public usdtToken;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint;
    using SafeMathUpgradeable for uint;

    mapping(address => uint) public stake;
    mapping(address => uint) public withdraw;
    mapping(address => bool) public whitelist;
    uint public whitestake;
    uint public totalStake;
    uint public totalGac;
    uint public minPrice;
    uint public maxPrice;
    uint[3] public endtime;
    uint public maxStakePerAddr;

    event SET_ENDTIME(address _sender, uint[3] _time);
    event SET_WHITE(address _sender, address _waddr);
    event SET_MAXSTAKE(address _sender, uint _val);
    event STAKE(address _sender, uint _amount);
    event REVERT(address _sender, uint _amount);
    event WITHDRAW(address _sender, uint _amount, uint _usdt);
    event ADMIN_WITHDRAW_USDT(address _sender, uint _amount);
    event ADMIN_WITHDRAW_GAC(address _sender, uint _amount);

    modifier checkCondition() {
        require(endtime[0] > 0, "endtime[0] > 0");
        require(maxStakePerAddr > 0, "maxStakePerAddr > 0");
        _;
    }

    function initialize(address _usdtToken, address _GacToken, uint _totalGac, uint _minPrice, uint _maxPrice) public initializer {
        BaseUpgradeable.__Base_init();

        GacToken = IERC20Upgradeable(_GacToken);
        usdtToken = IERC20Upgradeable(_usdtToken);
        minPrice = _minPrice;
        maxPrice = _maxPrice;
        totalGac = _totalGac;
        endtime = [block.timestamp + 30 days, block.timestamp + 60 days, block.timestamp + 90 days];
    }

    // reset endtime
    function set_endtime(uint[3] memory _endtime) external onlyAdmin {
        endtime = _endtime;

        emit SET_ENDTIME(msg.sender, _endtime);
    }

    function set_maxstake(uint _val) external onlyAdmin {
        maxStakePerAddr = _val;

        emit SET_MAXSTAKE(msg.sender, _val);
    }

    function set_white(address[] memory _addrs) external onlyAdmin {
        for (uint i = 0; i < _addrs.length; i++) {
            require(stake[msg.sender] == 0, "stake[msg.sender] == 0");
            whitelist[_addrs[i]] = true;
            emit SET_WHITE(msg.sender, _addrs[i]);
        }
    }

    function stake_usdt(uint _amount) checkCondition external {
        require(block.timestamp < endtime[0], "block.timestamp < endtime[0]");
        usdtToken.safeTransferFrom(msg.sender, address(this), _amount);
        stake[msg.sender] += _amount;
        totalStake += _amount;

        require(totalStake <= maxStakePerAddr, "totalStake <= maxStakePerAddr");

        if (whitelist[msg.sender]) {
            whitestake += _amount;
        }

        emit STAKE(msg.sender, _amount);
    }

    function revert_usdt(uint _amount) external {
        require(block.timestamp < endtime[1] && block.timestamp > endtime[0], "block.timestamp < endtime[1] and block.timestamp > endtime[0]");

        require(stake[msg.sender] >= _amount, "stake[msg.sender] >= _amount");

        usdtToken.safeTransfer(msg.sender, _amount);

        stake[msg.sender] -= _amount;
        totalStake -= _amount;

        if (whitelist[msg.sender]) {
            whitestake -= _amount;
        }

        emit REVERT(msg.sender, _amount);
    }

    function withdraw_Gac() external {
        require(block.timestamp < endtime[2] && block.timestamp > endtime[1], "block.timestamp < endtime[2] && block.timestamp > endtime[1]");
        require(stake[msg.sender] > 0, "stake[msg.sender] > 0");
        require(withdraw[msg.sender] == 0, "withdraw[msg.sender] == 0");

        uint _revertUSDT = 0;
        uint _amount = 0;

        // out
        if (totalStake > totalGac * maxPrice / 1e18) {
            if (whitelist[msg.sender]) { // in whitelist
                _amount = stake[msg.sender] * 1e18 / maxPrice;
            } else {
                uint _white_amount = whitestake * 1e18 / maxPrice;
                _amount = stake[msg.sender] * (totalGac - _white_amount) / (totalStake - whitestake);
                _revertUSDT = stake[msg.sender].sub(_amount * maxPrice / 1e18);
                usdtToken.safeTransfer(msg.sender, _revertUSDT);
            }
        } else {
            uint currPrice = (totalStake * 1e18 / totalGac).max(minPrice);
            _amount = stake[msg.sender] * 1e18 / currPrice;
        }

        withdraw[msg.sender] = _amount;
        GacToken.safeTransfer(msg.sender, _amount);

        emit WITHDRAW(msg.sender, _amount, _revertUSDT);
    }

    function admin_withdraw_usdt() external onlyAdmin {
        require(block.timestamp > endtime[2], "block.timestamp > endtime[2]");

        usdtToken.safeTransfer(msg.sender, usdtToken.balanceOf(address(this)));

        emit ADMIN_WITHDRAW_USDT(msg.sender, totalStake);
    }

    function admin_withdraw_gac() external onlyAdmin {
        require(block.timestamp > endtime[2], "block.timestamp > endtime[2]");

        GacToken.safeTransfer(msg.sender, GacToken.balanceOf(address(this)));

        emit ADMIN_WITHDRAW_GAC(msg.sender, totalStake);
    }
}
