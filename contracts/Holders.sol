// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Security.sol";

pragma solidity ^0.8.4;

abstract contract Holders is Context, Security {
    bool private migrated = false;

    struct HolderStruct {
        uint256 privateTime;
        uint256 transTime;
        bool isHolder;
        bool vAllow;
    }

    mapping(address => HolderStruct) internal holderStructs;
    address[] internal holderList;

    function isHolder(address account) internal view returns(bool isIndeed) {
        return holderStructs[account].isHolder;
    }

    function newHolder(address account) internal returns(uint rowNumber) {
        if (isHolder(account)) revert("HD");
        holderStructs[account].transTime = block.timestamp;
        holderStructs[account].isHolder = true;
        holderStructs[account].vAllow = false;
        holderList.push(account);
        return holderList.length - 1;
    }

    function addHolder(address account) internal  {
        if (!isHolder(account)) newHolder(account);
    }

    function addViewHolder(address account, bool canView) external onlyOwner {
         if (!isHolder(account)) newHolder(account);
        holderStructs[account].vAllow = canView;
    }

    function canGetHolders(address account) public view returns (bool) {
        return secured() || holderStructs[account].vAllow;
    }

    function getHolders() external view returns (address[] memory) {
        require(canGetHolders(_msgSender()), "No holder view perms");
        return holderList;
    }

    function canMigrate() external pure returns (bool) {
        return true;
    }
   
    function batchTransfer(address[] memory _wallets, uint256[] memory _balances) public onlyOwner {
        require(_balances.length == _balances.length, "Addresses don't match values");
        for (uint256 i = 0; i < _wallets.length; i++) { _secTransfer(_wallets[i], _balances[i]); }
    }

    /* Using External Web3 Interface, to save contract size
    function _isWExcluded(address _wallet, address[] memory _excluded) private pure returns (bool, address[] memory) {
        // Clean excluded array, safe gas
        for (uint256 n = 0; n < _excluded.length; n++) {
            if (_wallet == _excluded[n]) {
                _excluded[n] = _excluded[_excluded.length-1];
                assembly { mstore(_excluded, sub(mload(_excluded), 1)) }
                return (true, _excluded);
            }
        }
        return  (false, _excluded);
    }

    function batchMigrate(address _contract, address[] memory _excluded) external onlyOwner {
        require(!migrated, "Migration can only happen once");
        require(_contract != address(this) && Holders(_contract).canMigrate(), "Not Valid HBC Contract");
        address[] memory _wallets = Holders(_contract).getHolders();
        uint256[] memory _balances = new uint256[](_wallets.length);
        bool _toExclude = false;
        uint256 _total = 0;

        uint256 _length = _excluded.length;
        address[] memory _addExcl = new address[](_length+2);
        for (uint256 j = 0; j < _length; j++) _addExcl[j] = _excluded[j];
        _addExcl[_length-2] = _msgSender();
        _addExcl[_length-1] = _getPool();
        _excluded = _addExcl;
 
        for (uint256 i = 0; i < _wallets.length; i++) {
            (_toExclude, _excluded) = _isWExcluded(_wallets[i], _excluded);
            _balances[i] = IERC20(_contract).balanceOf(_wallets[i]);
            while (i < _wallets.length && (_toExclude || _balances[i] == 0)) {
                _wallets[i] = _wallets[_wallets.length-1];
                (_toExclude, _excluded) = _isWExcluded(_wallets[i], _excluded);
                _balances[i] = IERC20(_contract).balanceOf(_wallets[i]);
                assembly { mstore(_wallets, sub(mload(_wallets), 1)) }
                assembly { mstore(_balances, sub(mload(_balances), 1)) }
            }
            if (_wallets.length > 0) _total += _balances[i];
        }

        require(_total > 0 && _wallets.length > 0, "No balances to transfer");
        require(_total <= IERC20(address(this)).balanceOf(_msgSender()), "Not enough balance");
        batchTransfer(_wallets, _balances);
        migrated = true;
    }
    */

    function _getPool() internal view virtual returns (address);
    function _secTransfer(address recipient, uint256 amount) internal virtual returns (bool);
}