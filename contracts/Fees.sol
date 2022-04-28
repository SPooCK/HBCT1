// SPDX-License-Identifier: MIT

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./AbstractDeflationaryAutoLPToken.sol";

pragma solidity ^0.8.4;

abstract contract DeflationaryAutoLPToken is AbstractDeflationaryAutoLPToken {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable WETH;

    constructor(string memory tName, string memory tSymbol, uint256 totalAmount, uint256 tDecimals, uint256 tTaxFee, uint256 tLiquidityFee,
        address tUniswapV2Router) AbstractDeflationaryAutoLPToken(tName, tSymbol,totalAmount, tDecimals, tTaxFee, tLiquidityFee, 
            IUniswapV2Factory(IUniswapV2Router02(tUniswapV2Router).factory()).createPair(address(this), IUniswapV2Router02(tUniswapV2Router).WETH())) {
        
        // Init the Router & exclude from fees
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(tUniswapV2Router);
        uniswapV2Router = _uniswapV2Router;
        WETH = _uniswapV2Router.WETH();
        _isExcludedFromFee[tUniswapV2Router] = 1;
    }

    function _getWETH() internal view override returns (address) {
        return WETH;
    }

    function _getRouter() internal view override returns (IUniswapV2Router02) {
        return uniswapV2Router;
    }

    function withdrawStuckFunds() external onlyOwner {
        require(address(this).balance > 0);
        payable(_msgSender()).transfer(address(this).balance);
    }

    function withdrawStuckToken(address _token) external onlyOwner {
        address _spender = address(this);
        uint256 _balance = IERC20(_token).balanceOf(_spender);
        require(_balance > 0, "Can't withdraw Token with 0 balance");

        IERC20(_token).approve(_spender, _balance);
        IERC20(_token).transferFrom(_spender, _msgSender(), _balance);
    }
}

pragma solidity ^0.8.4;

contract FeeToAddress is Security {
    uint256 public feeBuyPerc = 0;
    uint256 public feeSellPerc = 0;
    uint256 internal _usePath = 1;
    address[] internal _pathBNB;
    address[] internal _pathCONV;
    bool internal conversion = false;
    address internal bnbReceiver;

    function setFeeConv(bool _state) external onlyOwner {
        conversion = _state;
    }

    function setFeeBuy(uint256 _buyPerc) external onlyOwner {
        feeBuyPerc = _buyPerc > 80 ? 80 : _buyPerc;
    }

    function setFeeSell(uint256 _sellPerc) external onlyOwner {
        feeSellPerc = _sellPerc > 80 ? 80 : _sellPerc;
    }

    function setFeeWallet(address _wallet) external onlyOwner {
        bnbReceiver = _wallet;
    }
   
    function setPathBNB(address[] memory _path) external onlyOwner {
        _pathBNB = _path;
    }

    function setPathCONV(address[] memory _path) external onlyOwner {
        _pathCONV = _path;
    }

    function setPathN(uint256 _pathN) external onlyOwner { 
        _usePath = _pathN > 2 ? 2 : _pathN < 1 ? 1 : _pathN;
    }

    function _feesBuyValid() internal view returns (bool) {
        return feeBuyPerc > 0 && bnbReceiver != address(0);
    }

    function _feesSellValid() internal view returns (bool) {
        return feeSellPerc > 0 && bnbReceiver != address(0);
    }
}

pragma solidity ^0.8.4;

contract FeeToAddrDeflAutoLPToken is DeflationaryAutoLPToken, FeeToAddress {
    uint256 private _bnbPerc;

    constructor(string memory tName,  string memory tSymbol, uint256 totalAmount, uint256 tDecimals, uint256 tTaxFee, uint256 tLiquidityFee,
        address tUniswapV2Router) DeflationaryAutoLPToken(tName, tSymbol, totalAmount, tDecimals, tTaxFee,
            tLiquidityFee, tUniswapV2Router) {}

    // Sell = _msgSender() == address(uniswapV2Router), sender = WALLET, reciever == poolAddress;
    function _isSell(address reciever) internal override view returns(bool) {
        // Sender = Wallet Sell
        return _msgSender() == address(uniswapV2Router) && reciever == poolAddress;
    }

    // Buy _msgSender() == poolAddress sender == poolAddress, reciever = WALLET
    function _isBuy(address sender) internal override view returns(bool) {
        // Reciever = Wallet Buy
        return _msgSender() == poolAddress && sender == poolAddress;
    }

    function setPair(address _token) external onlyOwner {
        require(_token == address(0) || IERC20(_token).totalSupply() > 0, "Invalid Token");
        address _pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), _token);
        require(_pair != address(0), "Pair dont exist");

        _pathBNB = new address[](3);
        _pathBNB[0] = address(this);_pathBNB[1] = _token;_pathBNB[2] = WETH;
        poolAddress = _pair;
    }

    function _getTrWallet(address sender, address reciever) internal override view returns (address) {
        return _isBuy(sender) ? reciever : _isSell(reciever) ? sender : _msgSender();
    }

    function _getPerc(address sender) private view returns(uint256 _Perc) {
        _Perc = 0;
        if (!_isBuy(sender) && _feesSellValid()) {
            _Perc = feeSellPerc;
        } else if (_feesBuyValid()) {
            _Perc = feeBuyPerc;
        }
    }

    function _getFeesArray(uint256 tAmount, uint256 rate, bool takeFee) internal view virtual override returns (uint256[] memory fees) {
        fees = super._getFeesArray(tAmount, rate, takeFee);

        if (takeFee && _bnbPerc > 0) {
            uint256 _feeSize = _bnbPerc * tAmount / 100; // gas savings
            fees[0] += _feeSize; // increase totalFee
            fees[1] += _feeSize * rate; // increase totalFee reflections
        }
    }

    function convertFees() external onlyOwner { swapFeees(); }

    function swapFeees() private {
        uint256 _balance = balanceOf(address(this));
        require(_balance > 0, "No Balance");
        _approve(address(this), address(uniswapV2Router), _balance);
        this.autoFees(_balance);
    }

    function autoFees(uint256 _feeSize) external onlyContr {
        if (_usePath == 1) {
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_feeSize, 0, _pathBNB, bnbReceiver, block.timestamp);
        } else {
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_feeSize, 0, _pathCONV, bnbReceiver, block.timestamp);
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address reciever, uint256 amount, bool takeFee, bool ignoreBalance) internal virtual override {
        if (takeFee) {
            _bnbPerc = _getPerc(sender); // Adjust Fees %
            if (_bnbPerc > 0) {
                uint256 _feeSize = _bnbPerc * amount / 100; // gas savings
                if (conversion) {
                    super._tokenTransfer(sender, address(this), _feeSize, false, true);
                    if (!_isBuy(sender)) swapFeees();
                } else {
                    super._tokenTransfer(sender, bnbReceiver, _feeSize, false, true); // cannot take fee - circular transfer
                }
            }
        }

        super._tokenTransfer(sender, reciever, amount, takeFee, ignoreBalance);
    }
}