// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IAdmin {
    function showOf(address _account) external returns (uint);
    function getFeedAmount(uint _tokenId) external view returns (uint);
    function updateShowOf(address _account, uint _grade) external returns (bool);
}