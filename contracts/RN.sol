// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract RN {

    // seed for generate RN
    uint private seed;

    /**
     * @dev get fake random number
     */
    function getRandomNumber() internal returns (uint) {
        bytes32 result = keccak256(abi.encodePacked(seed++, msg.sender, block.timestamp, block.coinbase, gasleft()));
        return uint(result);
    }

    /**
     * @dev random number within weight
     */
    function randomWeight(uint[] memory _weightList) internal returns (uint) {
        uint totalWeight;
        for (uint i = 0; i < _weightList.length; i++) {
            totalWeight += _weightList[i];
        }
        return randomWeight(_weightList, totalWeight);
    }

    /**
     * @dev random number within weight(pass in '_totalWeight' to cut down gas use)
     */
    function randomWeight(uint[] memory _weightList, uint _totalWeight) internal returns (uint) {
        require(0 < _totalWeight, "0 < _totalWeight");

        uint rn = getRandomNumber() % _totalWeight;
        uint count;
        for (uint i = 0; i < _weightList.length; i++) {
            count += _weightList[i];
            if (rn < count) return i;
        }
        revert("randomWeight error");
    }

    /**
     * @dev random number within weight
     */
    function randomWeight(uint[][] memory _weightList) internal returns (uint) {
        uint totalWeight;
        for (uint i = 0; i < _weightList.length; i++) {
            totalWeight += _weightList[i][1];
        }
        return randomWeight(_weightList, totalWeight);
    }

    /**
     * @dev random number within weight(pass in '_totalWeight' to cut down gas use)
     */
    function randomWeight(uint[][] memory _weightList, uint _totalWeight) internal returns (uint) {
        require(0 < _totalWeight, "0 < _totalWeight");

        uint rn = getRandomNumber() % _totalWeight;
        uint count;
        for (uint i = 0; i < _weightList.length; i++) {
            count += _weightList[i][1];
            if (rn < count) return i;
        }
        revert("randomWeight error");
    }

}
