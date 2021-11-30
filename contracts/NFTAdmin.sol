// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./BaseUpgradeable.sol";
import "./INFTAdmin.sol";
import "./IFamily.sol";
import "./IAdmin.sol";


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
contract NFTAdmin is ERC721EnumerableUpgradeable, INFTAdmin, BaseUpgradeable {
    using AddressUpgradeable for address;

    address public farm;
    address public adminAdmin;
    address public family;

    uint internal _currentTokenId;

    mapping(uint => TokenInfo) public _tokenInfoOf;

    // nft amount of each grade
    mapping(uint => uint) internal _amountOf;


    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function initialize(string memory name_, string memory symbol_) public initializer {
        BaseUpgradeable.__Base_init();
        ERC721EnumerableUpgradeable.__ERC721Enumerable_init();
        ERC721Upgradeable.__ERC721_init(name_, symbol_);

    }

    function setAdminAdmin(address _value) external onlyAdmin {
        adminAdmin = _value;
    }

    function setFamily(address _value) external onlyAdmin {
        family = _value;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(IERC165Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        // mint: _currentTokenId add one
        if (from == address(0)) {
            require(tokenId == ++_currentTokenId, "_beforeTokenTransfer: tokenId == ++_currentTokenId");
            // update amountOf
            _amountOf[_tokenInfoOf[tokenId].grade]++;
        }

        // update farm admin & show admin grad of
        TokenInfo memory tokenInfo = getTokenInfo(tokenId);
        if (address(0) != from && !from.isContract()) {
            // update show admin grade of
            uint currShow = IAdmin(adminAdmin).showOf(from);
            if (tokenId == currShow) {
                uint showTokenId = balanceOf(from) > 0 ? tokenOfOwnerByIndex(from, 0) : 0;
                IAdmin(adminAdmin).updateShowOf(from, showTokenId);
            }
            // update family
            IFamily(family).subPowerInfo(from, 0, 0, 0, 0, tokenInfo.grade, tokenInfo.exp);
        }
        if (address(0) != to && !to.isContract()) {
            // update show admin grade of
            uint currShow = IAdmin(adminAdmin).showOf(to);
            if (0 == currShow) {
                IAdmin(adminAdmin).updateShowOf(to, tokenId);
            }
            // update family
            IFamily(family).addPowerInfo(to, 0, 0, 0, 0, tokenInfo.grade, tokenInfo.exp);
        }
    }

    function currentTokenId() public view override returns (uint) {
        return _currentTokenId;
    }

    function amountOf(uint _grade) public view override returns (uint) {
        return _amountOf[_grade];
    }

    function getTokenInfo(uint _tokenId) public view override returns (TokenInfo memory) {
        require(_tokenId <= _currentTokenId, "_tokenId <= _currentTokenId");
        return _tokenInfoOf[_tokenId];
    }

    function getNFTs(address _account, uint _index, uint _offset) external view override returns (TokenInfo[] memory nfts) {
        uint totalSize = balanceOf(_account);
        if (totalSize <= _index) return nfts;
        if (totalSize < _index + _offset) {
            _offset = totalSize - _index;
        }

        nfts = new TokenInfo[](_offset);
        for (uint i = 0; i < _offset; i++) {
            nfts[i] = getTokenInfo(tokenOfOwnerByIndex(_account, _index + i));
        }
    }

    function getSpecifyNFTs(address _account, uint[] memory _tokenIds) external view override returns (TokenInfo[] memory nfts) {
        nfts = new TokenInfo[](_tokenIds.length);
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (ownerOf(_tokenIds[i]) != _account) {
                return new TokenInfo[](0);
            }
            nfts[i] = getTokenInfo(_tokenIds[i]);
        }
    }

    /**
     * @dev mint only by auth account
     */
    function mintOnlyBy(address _to, uint _tokenId , TokenInfo memory _tokenInfo) external override onlyAuth returns (bool) {
        _tokenInfo.tokenId = _tokenId;
        _tokenInfo.starGrade = 1;
        _tokenInfoOf[_tokenId] = _tokenInfo;
        _mint(_to, _tokenId);

        return true;
    }

    /**
     * @dev burn only by auth account
     */
    function burnOnlyBy(uint _tokenId) external override onlyAuth returns (bool) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");
        _burn(_tokenId);

        return true;
    }

    /**
     * @dev batch mint only by auth account
     */
    function batchMint(address _to, uint _amount, uint[] memory _args) external override onlyAuth returns (bool) {
        for (uint i = 0; i < _amount; i++) {
            uint tokenId = _currentTokenId + 1;
            TokenInfo memory tokenInfo;
            tokenInfo.tokenId = tokenId;
            tokenInfo.grade = _args[0];
            tokenInfo.color = _args[1];
            tokenInfo.starGrade = _args[2];
            _tokenInfoOf[tokenId] = tokenInfo;
            _mint(_to, tokenId);
        }

        return true;
    }

    /**
     * @dev update tokenInfo by _tokenId
     */
    function update(uint _tokenId, TokenInfo memory _tokenInfo) external override onlyAuth returns (bool) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");
        TokenInfo memory tokenInfo = _tokenInfoOf[_tokenId];
        _tokenInfoOf[_tokenId] = _tokenInfo;

        emit Update(msg.sender, _tokenId, tokenInfo, _tokenInfo);

        // update family
        if (_tokenInfo.exp > tokenInfo.exp) {
            IFamily(family).subPowerInfo(ownerOf(_tokenId), 0, 0, 0, 0, tokenInfo.grade, tokenInfo.exp);
            IFamily(family).addPowerInfo(ownerOf(_tokenId), 0, 0, 0, 0, tokenInfo.grade, _tokenInfo.exp);
        }
        return true;
    }

}
