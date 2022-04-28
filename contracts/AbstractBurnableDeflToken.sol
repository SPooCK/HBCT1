// SPDX-License-Identifier: MIT

import "./AbstractDeflationaryToken.sol";

pragma solidity ^0.8.4;

abstract contract AbstractBurnableDeflToken is AbstractDeflationaryToken {
    uint256 public totalBurned;

    function burn(uint256 amount) external onlyOwner {
        require(balanceOf(_msgSender()) >= amount, "Not enough tokens");
        totalBurned += amount;

        if (_isExcludedFromReward[_msgSender()] == 1) {
            _tOwned[_msgSender()] -= amount;

            emit Transfer(_msgSender(), address(0), amount);
        } else {
            uint256 rate = _getRate();
            _rOwned[_msgSender()] -= amount * rate;
            _tIncludedInReward -= amount;
            _rIncludedInReward -= amount * rate;

            emit Transfer(_msgSender(), address(0), amount * rate);
        }
    }

    function restore() external onlyOwner {
        require(totalBurned > 0, "There is no burned tokens");

        if (_isExcludedFromReward[_msgSender()] == 1) {
            _tOwned[_msgSender()] += totalBurned;
        } else {
            _rOwned[_msgSender()] += totalBurned;
            _tIncludedInReward += totalBurned;
            _rIncludedInReward += totalBurned;
        }

        totalBurned = 0;
    }
}
