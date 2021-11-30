// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "./INFTEquipment.sol";
import "./BaseUpgradeable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
contract NFTEquipment is ERC721EnumerableUpgradeable, INFTEquipment, BaseUpgradeable {

    uint internal _currentTokenId;

    mapping(uint => TokenInfo) public _tokenInfoOf;


    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function initialize(string memory name_, string memory symbol_) public initializer {
        BaseUpgradeable.__Base_init();
        ERC721EnumerableUpgradeable.__ERC721Enumerable_init();
        ERC721Upgradeable.__ERC721_init(name_, symbol_);

    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
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
    function _beforeTokenTransfer(address from, address to, uint tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            require(tokenId == ++_currentTokenId, "_beforeTokenTransfer: tokenId == ++_currentTokenId");
        }
    }

    function currentTokenId() public view override returns (uint) {
        return _currentTokenId;
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

    /**
     * @dev mint only by auth account
     */
    function mintOnlyBy(address _to, uint _tokenId , TokenInfo memory _tokenInfo) external override onlyAuth returns (bool) {
        _tokenInfo.tokenId = _tokenId;
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
            tokenInfo.level = _args[1];
            tokenInfo.quality = _args[2];
            tokenInfo.star = _args[3];
            tokenInfo.durability = _args[4];
            _tokenInfoOf[tokenId] = tokenInfo;
            _mint(_to, tokenId);
        }

        return true;
    }

    function getSpecifyNFTs(address _account, uint[] memory _tokenIds) external view returns (TokenInfo[] memory nfts) {
        nfts = new TokenInfo[](_tokenIds.length);
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (ownerOf(_tokenIds[i]) != _account) {
                return new TokenInfo[](0);
            }
            nfts[i] = getTokenInfo(_tokenIds[i]);
        }
    }

    /**
     * @dev update tokenInfo by _tokenId
     */
    function update(uint _tokenId, TokenInfo memory _tokenInfo) external override onlyAuth returns (bool) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");
        TokenInfo memory tokenInfo = _tokenInfoOf[_tokenId];
        _tokenInfoOf[_tokenId] = _tokenInfo;

        emit Update(msg.sender, _tokenId, tokenInfo, _tokenInfo);
        return true;
    }

}
