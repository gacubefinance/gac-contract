// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library Constants {
    address payable constant BURN_ADDRESS = payable(0x000000000000000000000000000000000000dEaD);
    address payable constant ORG_RECEIPT_ADDRESS = payable(0xa38E5cDcDD436773ce226e3EDD4ec18708f96FE9);
    address payable constant GFB_RECEIPT_ADDRESS = payable(0xa38E5cDcDD436773ce226e3EDD4ec18708f96FE9);

    uint constant TREE_ID = 210001;
    uint constant FRUIT_ID = 220001;
    uint constant FISH_ID = 240013;
    uint constant EQUIPMENT_BOX_ID = 261201;
    uint constant ADMIN_FRAGMENT_ID = 263101;
    uint constant ROD_ID = 265001;


    function FIELD_IDS() internal pure returns (uint[] memory res) {
        uint[8] memory const = [uint(271001), 271002, 272001, 272002, 272003, 272004, 272005, 272006];
        res = new uint[](const.length);
        for (uint i = 0; i < res.length; i++) {res[i] = const[i];}
    }

    function FIELD_MAIN_IDS() internal pure returns (uint[] memory res) {
        uint[2] memory const = [uint(271001), 271002];
        res = new uint[](const.length);
        for (uint i = 0; i < res.length; i++) {res[i] = const[i];}
    }

    function FIELD_KINGDOM_IDS() internal pure returns (uint[] memory res) {
        uint[6] memory const = [uint(272001), 272002, 272003, 272004, 272005, 272006];
        res = new uint[](const.length);
        for (uint i = 0; i < res.length; i++) {res[i] = const[i];}
    }

}