// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BaseUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract IDO is BaseUpgradeable {
    IERC20Upgradeable public GacToken;
    IERC20Upgradeable public usdtToken;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint;
    using SafeMathUpgradeable for uint;

    struct ido_rec {
        address addr;
        uint time;
        uint num;
    }

    mapping(uint => ido_rec) public his;
    mapping(address => uint) public stake;
    mapping(address => uint) public withdraw;
    mapping(address => bool) public whitelist;

    uint public hisID;
    uint public whitestake;
    uint public totalStake;
    uint public totalGac;
    uint public minPrice;
    uint public maxPrice;
    uint public maxStake;
    uint[2] public endtime;
    uint public maxStakePerAddr;
    address[] public joinAddrList;

    event SET_ENDTIME(address _sender, uint[2] _time);
    event SET_WHITE(address _sender, address _waddr);
    event SET_MAXSTAKE(address _sender, uint _val);
    event STAKE(address _sender, uint _amount);
    event REVERT(address _sender, uint _amount);
    event WITHDRAW(address _sender, uint _amount, uint _usdt);
    event ADMIN_WITHDRAW_USDT(address _sender, uint _amount);
    event ADMIN_WITHDRAW_GAC(address _sender, uint _amount);

    modifier checkCondition() {
        require(endtime[0] > 0, "104101");
        require(maxStakePerAddr > 0, "104102");
        _;
    }

    function initialize(address _usdtToken, address _GacToken, uint _totalGac, uint _minPrice, uint _maxPrice,
        uint _maxStake, uint _maxStakePerAddr) public initializer {
        BaseUpgradeable.__Base_init();

        require(_minPrice <= _maxPrice, "104103");
        GacToken = IERC20Upgradeable(_GacToken);
        usdtToken = IERC20Upgradeable(_usdtToken);
        minPrice = _minPrice;
        maxPrice = _maxPrice;
        maxStake = _maxStake;
        totalGac = _totalGac;
        maxStakePerAddr = _maxStakePerAddr;
        endtime = [block.timestamp + 24 hours, block.timestamp + 30 days];
    }

    // reset endtime
    function set_endtime(uint[2] memory _endtime) external onlyAdmin {
        endtime = _endtime;

        emit SET_ENDTIME(msg.sender, _endtime);
    }

    function set_usdt(address _addr) external onlyAdmin {
        usdtToken = IERC20Upgradeable(_addr);
    }

    function set_white(address[] memory _addrs) external onlyAdmin {
        for (uint i = 0; i < _addrs.length; i++) {
            require(stake[msg.sender] == 0, "104104");
            whitelist[_addrs[i]] = true;
            emit SET_WHITE(msg.sender, _addrs[i]);
        }
    }

    function stake_usdt(uint _amount) checkCondition notPaused external {
        require(block.timestamp < endtime[0], "104105");
        usdtToken.safeTransferFrom(msg.sender, address(this), _amount);
        stake[msg.sender] += _amount;
        totalStake += _amount;

        require(totalStake <= maxStake, "104106");
        require(stake[msg.sender] <= maxStakePerAddr, "104113");

        joinAddrList.push(msg.sender);

        if (whitelist[msg.sender]) {
            whitestake += _amount;
        }

        hisID++;
        ido_rec memory idoData;
        idoData.addr = msg.sender;
        idoData.time = block.timestamp;
        idoData.num = _amount;
        his[hisID] = idoData;

        emit STAKE(msg.sender, _amount);
    }

    function hisList(uint _index, uint _offset) public view
        returns(ido_rec[] memory _data) {
        uint totalSize = hisID;
        if (totalSize == 0) {
            _data = new ido_rec[](0);
        } else {
            require(0 < totalSize && totalSize >= _index, "104107");
            if (totalSize < _index + _offset) {
                _offset = totalSize - _index;
            }

            _data = new ido_rec[](_offset);
            for (uint i = 0; i < _offset; i++) {
                _data[i] = his[_index + i + 1];
            }
        }

    }

    function price() public view returns(uint) {
        if (totalStake > totalGac * maxPrice / 1e18) {
            return maxPrice;
        } else {
            return (totalStake * 1e18 / totalGac).max(minPrice);
        }
    }

    function withdraw_Gac() external {
        require(block.timestamp > endtime[1], "104108");
        require(stake[msg.sender] > 0, "104109");
        require(withdraw[msg.sender] == 0, "104110");

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
        require(block.timestamp > endtime[1], "104111");

        usdtToken.safeTransfer(msg.sender, usdtToken.balanceOf(address(this)));

        emit ADMIN_WITHDRAW_USDT(msg.sender, totalStake);
    }

    function admin_withdraw_gac() external onlyAdmin {
        require(block.timestamp > endtime[1], "104112");

        GacToken.safeTransfer(msg.sender, GacToken.balanceOf(address(this)));

        emit ADMIN_WITHDRAW_GAC(msg.sender, totalStake);
    }
}
