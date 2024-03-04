// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Mindx is ERC20, Ownable {
    using Address for address payable;

    mapping(address => bool) _isExcludedMaxTransactionAmount;
    mapping(address => bool) _automatedMarketMaker;

    uint256 public liquidityFeeOnBuy;
    uint256 public liquidityFeeOnSell;
    uint256 public RevenueShare;
    uint256 public OwnerShare;
    bool private swapping;
    bool public tradingEnabled;
    address public uniswapV2Pair;
    address public TechTeam = 0x60FF0d52212B896438E2f6f35c5A75e0229539db;
    address public TreasuryRevenue = 0x60FF0d52212B896438E2f6f35c5A75e0229539db;
    address public TreasuryOwner = 0x60FF0d52212B896438E2f6f35c5A75e0229539db;

    mapping (address => uint256) public _tierTimestamp;


    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdateWalletToWalletTransferFee(uint256 walletToWalletTransferFee);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapAndSendMarketing(uint256 tokensSwapped, uint256 bnbSend);
    event adding_isExcluded(address _address);
    event removing_isExcluded(address _address);
    event adding_automated(address _address);
    event removing_automated(address _address);
    event enable_trading(bool _status);
    event tax_change(uint _b, uint _s);
    event tax_Treasury(address _b, address _s);
    event tax_fee(uint _b, uint _s);

    constructor() ERC20("Mindx", "MAI") {
        _automatedMarketMaker[msg.sender] = true;
        _automatedMarketMaker[TechTeam] = true;
        _automatedMarketMaker[TreasuryRevenue] = true;
        _automatedMarketMaker[TreasuryOwner] = true;

        _mint(owner(), 720 * 1e24); //720m
        uint total_Supply = balanceOf(owner());

        uint techTeam = (total_Supply / 100) * 5; //tech team share
        transfer(TechTeam, techTeam);

        tradingEnabled = true;
        liquidityFeeOnBuy = 5;
        liquidityFeeOnSell = 5;
    }

    receive() external payable {}

    function enableTrading(bool _status) external onlyOwner {
        require(!tradingEnabled, "Trading already enabled.");
        tradingEnabled = _status;
        emit enable_trading(_status);
    }

    function taxChange(uint _b, uint _s) external onlyOwner {
        liquidityFeeOnBuy = _b;
        liquidityFeeOnSell = _s;

        emit tax_change(_b, _s);
    }

    function divChange(uint _b, uint _s) external onlyOwner {
        liquidityFeeOnBuy = _b;
        liquidityFeeOnSell = _s;

        emit tax_fee(_b, _s);
    }

    function divAdress(address _tr, address _to) external onlyOwner {
        TreasuryRevenue = _tr;
        TreasuryOwner = _to;

        emit tax_Treasury(_tr, _to);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!tradingEnabled, "ERC20: trade is not available");
        uint Taxation = 0;
        if (_automatedMarketMaker[from] || _automatedMarketMaker[to]) {
            Taxation = 0;
        } else {
            if (_isExcludedMaxTransactionAmount[from]) {
                //buy
                Taxation = liquidityFeeOnBuy;
            } else if (_isExcludedMaxTransactionAmount[to]) {
                //sell
                Taxation = liquidityFeeOnSell;
            }
        }

        Taxation = (amount / 100) * Taxation;

        if (Taxation > 0) {
            uint _owner_share = (Taxation / 100) * OwnerShare;
            uint _revenue_share = Taxation - _owner_share;
            super._transfer(from, TreasuryRevenue, _revenue_share);
            super._transfer(from, TreasuryOwner, _owner_share);
        }
        _tierTimestamp[to] = block.timestamp;
        _tierTimestamp[from] = block.timestamp;

        super._transfer(from, to, amount - Taxation);
    }

    function adding_isExcludedMaxTransactionAmount(address _a) public onlyOwner{
        _isExcludedMaxTransactionAmount[_a] = true;
        emit adding_isExcluded(_a);
    }

    function removing_isExcludedMaxTransactionAmount(address _a) public onlyOwner{
        delete _isExcludedMaxTransactionAmount[_a];
        emit removing_isExcluded(_a);
    }

    function adding_automatedMarketMakerPairs(address _a) public onlyOwner {
        _automatedMarketMaker[_a] = true;
        emit adding_automated(_a);
    }

    function removing_automatedMarketMakerPairs(address _a) public onlyOwner{
        delete _automatedMarketMaker[_a];
        emit removing_automated(_a);
    }
   
    function getTier(address account) public view returns (uint ) {
        return _tierTimestamp[account];
    }
}
