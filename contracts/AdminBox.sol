// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./Constants.sol";
import "./RN.sol";
import "./INFTAdmin.sol";
import "./BaseUpgradeable.sol";
import "./config/ConfigBase.sol";


contract AdminBox is BaseUpgradeable, RN {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ///////////////////////////////// constant /////////////////////////////////
    ConfigBase public config;
    address public gacToken;
    address public nftAdmin;

    uint constant ADMIN_BOX_ID = 273003;


    ///////////////////////////////// storage /////////////////////////////////
    uint public startTime;

    uint public storageCount;
    uint[][] public storageNum;


    event BuyBox(address indexed from, uint tokenId, uint grade, uint color);

    function initialize(address _gacToken, address _nftAdmin) public initializer {
        BaseUpgradeable.__Base_init();

        gacToken = _gacToken;
        nftAdmin = _nftAdmin;

    }


    modifier isServing() {
        require(!isPaused, "!isPaused");
        require(block.timestamp >= startTime, "block.timestamp >= startTime");
        require(address(0) != address(config), "address(0) != address(config)");
        require(address(0) != gacToken, "address(0) != orgToken");
        require(address(0) != nftAdmin, "address(0) != nftAdmin");
        _;
    }

    function setConfig(address _value) external onlyAdmin {
        config = ConfigBase(_value);
        // init storage
        _initStorage();
    }

    function setgacToken(address _value) external onlyAdmin {
        gacToken = _value;
    }

    function setNftAdmin(address _value) external onlyAdmin {
        nftAdmin = _value;
    }

    function setStartTime(uint _value) external onlyAdmin {
        startTime = _value;
    }

    function getStorageNum() external view returns (uint[][] memory) {
        return storageNum;
    }

    function buyBox(uint _amount) external isServing onlyExternal {
        require(0 < _amount, "000003");

        // transfer org
        uint price = config.getUint("AdminBoxConf", "value_gac", ADMIN_BOX_ID) * _amount;
        dividends(price);

        for (uint i = 0; i < _amount; i++) {
            uint rn = RN.randomWeight(storageNum);
            uint grade = storageNum[rn][0];
            uint color = storageNum[rn][2];

            // update storageNum
            storageNum[rn][1]--;
            storageCount--;

            uint tokenId = INFTAdmin(nftAdmin).currentTokenId() + 1;
            INFTAdmin.TokenInfo memory tokenInfo;
            tokenInfo.grade = grade;
            tokenInfo.color = color;
            INFTAdmin(nftAdmin).mintOnlyBy(msg.sender, tokenId, tokenInfo);

            emit BuyBox(msg.sender, tokenId, grade, color);
        }
    }

    function _initStorage() private {
        storageNum = config.getUintArray2("AdminBoxConf", "rate", ADMIN_BOX_ID);
        for (uint i = 0; i < storageNum.length; i++) {
            storageCount += storageNum[i][1];
        }
    }

    // 分红
    function dividends(uint _amount) private {
        require(0 < _amount, "000003");
        address[2] memory accounts = [0x72F3f65f5841CAF3C5dAa37FA911677aA9251F83, 0x48859228aD93CC8561C18CAc7484866999738b1d];
        uint8[2] memory ratePer = [85, 15];
        for (uint i = 0; i < accounts.length; i++) {
            IERC20Upgradeable(gacToken).safeTransferFrom(msg.sender, accounts[i], _amount * ratePer[i] / 100);
        }
    }

}
