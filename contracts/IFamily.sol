// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFamily {
    struct memberInfo {
        uint fid; // 工会ID
        uint fish; // 果实算力
        uint fruit; // 果实算力
        uint admin; // 管理员算力
        uint time; // 加入时间
        bytes32 name;
    }

    function addPowerInfo(address _addr, uint _fruitId, uint _fruitAmount, uint _fishId, uint _fishAmount, uint _adminGrade, uint _adminExp) external;
    function subPowerInfo(address _addr, uint _fruitId, uint _fruitAmount, uint _fishId, uint _fishAmount, uint _adminGrade, uint _adminExp) external;

    function getMemberInfo(address _mAddr) external view returns (memberInfo memory);
}
