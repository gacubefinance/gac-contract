// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface INFTEquipment is IERC721EnumerableUpgradeable {
    struct TokenInfo {
        uint tokenId;
        uint grade;// 类型
        uint level; // 等级
        uint durability; // 耐用度
        uint quality; // 品质
        uint star; // 升星 原熔炼
    }

    event Update(address indexed oprator, uint indexed tokenId, TokenInfo oldTokenInfo, TokenInfo newTokenInfo);

    function currentTokenId() external view returns (uint);
    function getTokenInfo(uint _tokenId) external view returns (TokenInfo memory);
    function getNFTs(address _account, uint _index, uint _offset) external view returns (TokenInfo[] memory nfts);
    function mintOnlyBy(address _to, uint _tokenId , TokenInfo memory _tokenInfo) external returns (bool);
    function burnOnlyBy(uint _tokenId) external returns (bool);
    function batchMint(address _to, uint _amount, uint[] memory _args) external returns (bool);
    function update(uint _tokenId, TokenInfo memory _tokenInfo) external returns (bool);
}
