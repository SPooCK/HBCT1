// SPDX-License-Identifier: MIT

import "./AbstractBurnableDeflToken.sol";

pragma solidity ^0.8.4;

abstract contract AbstractDeflationaryAutoLPToken is AbstractDeflationaryToken {
    uint256 private _tAllowance = 0;
    
    uint256 public _liquidityFee;
    address public poolAddress;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived, uint256 tokensIntoLiqudity);
    event Log(string message, address wallet);

    constructor(string memory tName, string memory tSymbol, uint256 totalAmount, uint256 tDecimals, uint256 tTaxFee, uint256 tLiquidityFee, address liquidityPoolAddress)
        AbstractDeflationaryToken(tName, tSymbol, totalAmount, tDecimals, tTaxFee) {
        _liquidityFee = tLiquidityFee;
        poolAddress = liquidityPoolAddress;
    }

    receive() external payable virtual {}

    function inTAllowance(uint256 amount, address _account) private view returns (bool) {
        if (_tAllowance != 0 && !securedAdr(_account)) {
            uint256 _left = ((getLiquidity(false) * _tAllowance) / 100);
            return amount <= _left;
        }
        return true;
    }

    function getLiquidity(bool _useWETH) private view returns (uint256) {
        IUniswapV2Pair _pair = IUniswapV2Pair(poolAddress);
        (uint256 _Token, uint256 _WETH,) = _pair.getReserves();
        (_Token, _WETH) = _pair.token0() == address(this) ? (_Token, _WETH) : (_WETH, _Token);
        return _useWETH ? _WETH : _Token;
    }

    function setTAllowance(uint256 _percentage) external onlyOwner {
        _tAllowance = _percentage > 100 ? 100 : _percentage;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    function _takeLiquidity(uint256 tLiquidity, uint256 rate) internal {
        if (tLiquidity == 0) return;

        if (_isExcludedFromReward[poolAddress] == 1) {
            _tOwned[poolAddress] += tLiquidity;
            _tIncludedInReward -= tLiquidity;
            _rIncludedInReward -= tLiquidity * rate;
        } else {
            _rOwned[poolAddress] += tLiquidity * rate;
        }
    }

    function _getTransferAmount(uint256 tAmount, uint256 totalFeesForTx, uint256 rate) internal view virtual override 
    returns (uint256 tTransferAmount, uint256 rTransferAmount) {
        tTransferAmount = tAmount - totalFeesForTx;
        rTransferAmount = tTransferAmount * rate;
    }

    function _recalculateRewardPool(bool isSenderExcluded, bool isRecipientExcluded, uint256[] memory fees, uint256 tAmount,
        uint256 rAmount, uint256 tTransferAmount,uint256 rTransferAmount
    ) internal virtual override {
        if (isSenderExcluded) {
            if (isRecipientExcluded) {
                _tIncludedInReward += fees[0];
                _rIncludedInReward += fees[1];
            } else {
                _tIncludedInReward += tAmount;
                _rIncludedInReward += rAmount;
            }
        } else {
            if (isRecipientExcluded) {
                if (!isSenderExcluded) {
                    _tIncludedInReward -= tTransferAmount;
                    _rIncludedInReward -= rTransferAmount;
                }
            }
        }
    }

    function _transfer(address sender, address reciever, uint256 amount) internal virtual override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(reciever != address(0), "ERC20: transfer to the zero address");
        require(amount != 0, "Transfer amount can't be zero");

        // Get the user Wallet
        address _account = _getTrWallet(sender, reciever);
        // Compare % Liquidity transfer allowance --- FIX ONLY TO APPLY FOR SELL ---
        require(inTAllowance(amount, _account), "Above max % transfer allowance");
        // Limit Cool Down only to Liuquidity
        if (_lToSwap && (_isBuy(sender) || _isSell(sender))) _canTransfer(_account);

        //if any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = _isExcludedFromFee[sender] == 0 && _isExcludedFromFee[reciever] == 0;

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(sender, reciever, amount, takeFee, false);
    }
    
    function _getFeesArray(uint256 tAmount, uint256 rate, bool takeFee) internal view virtual override returns (uint256[] memory fees) {
        fees = new uint256[](5);
        if (takeFee) {
            // Holders fee
            fees[2] = (tAmount * _taxHolderFee) / 100; // t
            fees[3] = fees[2] * rate; // r

            // liquidity fee
            fees[4] = (tAmount * _liquidityFee) / 100; // t

            // Total fees
            fees[0] = fees[2] + fees[4]; // t
            fees[1] = fees[3] + fees[4] * rate; // r
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool ignoreBalance) internal virtual override {
        uint256 rate = _getRate();
        uint256 rAmount = amount * rate;
        uint256[] memory fees = _getFeesArray(amount, rate, takeFee);

        (uint256 tTransferAmount, uint256 rTransferAmount) = _getTransferAmount(amount,fees[0],rate);
        {
            bool isSenderExcluded = _isExcludedFromReward[sender] == 1;
            bool isRecipientExcluded = _isExcludedFromReward[recipient] == 1;

            if (isSenderExcluded) {
                _tOwned[sender] -= ignoreBalance ? 0 : amount;
            } else {
                _rOwned[sender] -= ignoreBalance ? 0 : rAmount;
            }

            if (isRecipientExcluded) {
                _tOwned[recipient] += tTransferAmount;
            } else {
                _rOwned[recipient] += rTransferAmount;
            }

            if (!ignoreBalance)
                _recalculateRewardPool(
                    isSenderExcluded,
                    isRecipientExcluded,
                    fees,
                    amount,
                    rAmount,
                    tTransferAmount,
                    rTransferAmount
                );
        }

        _takeLiquidity(fees[4], rate);
        _reflectHolderFee(fees[2], fees[3]);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getPool() internal view override returns (address) {
        return poolAddress;
    }
}