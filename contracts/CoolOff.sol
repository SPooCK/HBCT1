// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Security.sol";
import "./Holders.sol";

pragma solidity ^0.8.4;

abstract contract CoolOff is SecPausable, Holders {
    uint256 private _lastGTrans = block.timestamp;
    uint256 private _globalDelay = 0;
    uint256 private _personalDelay = 0;
    bool internal _lToSwap = false;

    function _canTransfer(address _account) internal {
        if (securedAdr(_account)) return;

        if (_globalDelay != 0) {
            uint256 _time = _atGDelay();
            require(_time == 0, string(abi.encodePacked("Contract CD sec: ", Strings.toString(_time))));

            _lastGTrans = block.timestamp + _globalDelay;
        }

        if (_account != address(0) && isHolder(_account)) {
            uint256 _prTime = holderStructs[_account].privateTime;

            if (_prTime != 0) {
                require(_prTime > 1, "Personal Wallet Paused");
                uint256 _time = _atPrDelay(_prTime);
                require(_time == 0, string(abi.encodePacked("Personal Wallet CD sec: ", Strings.toString(_time))));
                holderStructs[_account].privateTime = 0;
            }

            if (_personalDelay != 0) {
                uint256 _time = _atPDelay(_account);
                require(_time == 0, string(abi.encodePacked("Wallet CD sec: ", Strings.toString(_time))));
                holderStructs[_account].transTime = block.timestamp + _personalDelay;
            }
        }
    }

    function _atGDelay() internal view returns (uint256) {
        bool _delay; uint256 _time;
        (_delay, _time) = SafeMath.trySub(_lastGTrans, block.timestamp);
        return _time;
    }

    function _atPDelay(address _account) internal view returns (uint256) {
        bool _delay; uint256 _time;
        uint256 _lastPTrans = holderStructs[_account].transTime;
        (_delay, _time) = SafeMath.trySub(_lastPTrans, block.timestamp); 
        return _time;
    }

    function _atPrDelay(uint256 prDelay) internal view returns (uint256) {
        bool _delay; uint256 _time;
        (_delay, _time) = SafeMath.trySub(prDelay, block.timestamp); 
        return _time;
    }

    function _getGDelay() internal view returns (uint256) {
        return _globalDelay;
    }

    function _getPDelay() internal view returns (uint256) {
        return _personalDelay;
    }

    function getPrDelay(address _account) external view onlyOwner returns (uint256) {
        return holderStructs[_account].privateTime;
    }

    function setGDelay(uint256 _secDelay) external onlyOwner {
        _globalDelay = _secDelay;
    }

    function setPDelay(uint256 _secDelay) external onlyOwner {
        _personalDelay = _secDelay;
    }

    function setPrDelay(address _account, uint256 _secDelay) external onlyOwner {
        require(!securedAdr(_account), "Ownable: Cannot assign to contract owner");
        if (_secDelay == 0 || _secDelay == 1) {
            holderStructs[_account].privateTime = _secDelay;
        } else {
            holderStructs[_account].privateTime = block.timestamp + _secDelay;
        }
    }

    function setLToSwap(bool _limit) external onlyOwner {
        _lToSwap = _limit;
    }

    function _isBuy(address sender) internal virtual view returns(bool);
    function _isSell(address reciever) internal virtual view returns(bool);
    function _getTrWallet(address sender, address reciever) internal virtual view returns (address);
}