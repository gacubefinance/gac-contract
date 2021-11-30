// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface INFTAdmin is IERC721EnumerableUpgradeable {
    struct TokenInfo {
        uint tokenId;           // NFTAdmin TokenId
        uint grade;             // 类型
        uint exp;               // 等级经验
        uint color;             // 品质
        uint skillExp1;         // 技能1经验
        uint skillExp2;         // 技能2经验
        uint skillExp3;         // 技能3经验
        uint starGrade;         // 星级
        uint nextBreedTime;     // 下次繁育时间
        uint skin;
        uint[] skinType;
    }

    event Update(address indexed oprator, uint indexed tokenId, TokenInfo oldTokenInfo, TokenInfo newTokenInfo);

    function currentTokenId() external view returns (uint);
    function getTokenInfo(uint _tokenId) external view returns (TokenInfo memory);
    function getNFTs(address _account, uint _index, uint _offset) external view returns (TokenInfo[] memory nfts);
    function getSpecifyNFTs(address _account, uint[] memory _tokenIds) external view returns (TokenInfo[] memory nfts);
    function amountOf(uint _grade) external view returns (uint);
    function mintOnlyBy(address _to, uint _tokenId , TokenInfo memory _tokenInfo) external returns (bool);
    function burnOnlyBy(uint _tokenId) external returns (bool);
    function batchMint(address _to, uint _amount, uint[] memory _args) external returns (bool);
    function update(uint _tokenId, TokenInfo memory _tokenInfo) external returns (bool);
}
