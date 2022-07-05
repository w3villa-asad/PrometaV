// SPDX-License-Identifier:None

    pragma solidity ^0.8.0;
/* IMPORTS */

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
// import "hardhat/console.sol";

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
    abstract contract ReentrancyGuard {
        // Booleans are more expensive than uint256 or any type that takes up a full
        // word because each write operation emits an extra SLOAD to first read the
        // slot's contents, replace the bits taken up by the boolean, and then write
        // back. This is the compiler's defense against contract upgrades and
        // pointer aliasing, and it cannot be disabled.

        // The values being non-zero value makes deployment a bit more expensive,
        // but in exchange the refund on every call to nonReentrant will be lower in
        // amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to
        // increase the likelihood of the full refund coming into effect.
        uint256 private constant _NOT_ENTERED = 1;
        uint256 private constant _ENTERED = 2;

        uint256 private _status;

        constructor() {
            _status = _NOT_ENTERED;
        }

        /**
        * @dev Prevents a contract from calling itself, directly or indirectly.
        * Calling a `nonReentrant` function from another `nonReentrant`
        * function is not supported. It is possible to prevent this from happening
        * by making the `nonReentrant` function external, and making it call a
        * `private` function that does the actual work.
        */
        modifier nonReentrant() {
            // On the first call to nonReentrant, _notEntered will be true
            require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

            // Any calls to nonReentrant after this point will fail
            _status = _ENTERED;

            _;

            // By storing the original value once again, a refund is triggered (see
            // https://eips.ethereum.org/EIPS/eip-2200)
            _status = _NOT_ENTERED;
        }
    }


    interface IPrometaV {

    function transfer(address recipient, uint256 amount) external;

    }

// PreSale - $0.01

contract PrometaVPrivateSale is ReentrancyGuard, Ownable {
    
    using SafeMath for uint256;

    IPrometaV public prometaV;
    AggregatorV3Interface internal ethPriceFeed;

    uint256 public saleStart;
    uint256 public saleEnd;
    uint256 public supply = 45_000_000 ether; // private sale supply = 45000000
    uint256 public distributed;

    uint256 public salePriceUsd = 10000000000000000; //$0.01

    mapping(address => uint256) public toRefund;

    // address of admin
    address public adminAddress;

    // contract balance
    uint256 public balance;

    //address of PrometaV
    address pmvAddress;


    mapping (address => uint256) public _toClaim;


    // eth deposit mapping
    mapping (address => uint256) public  _ethDeposit;
    
    /* EVENTS */
        event Bought(address account, uint256 amount);
        event Locked(address account, uint256 amount);
        event Released(address account, uint256 amount);

        event Buy(address indexed from, uint256 amount);
        event Destroyed(uint256 burnedFunds);
        event Transferred(address indexed to, uint256 amount);

        event withdrawnETHDeposit(address indexed to, uint256 amount);

        event Transfer(address indexed from, address indexed to, uint256 value); // IERC20.sol: Transfer(address, address, uint256)
    // 
    
    /* CONSTRUCTOR */
        constructor(
            // address _prometaV,
            uint256 _saleStart,
            uint256 _saleEnd
        ) {
            require(
                _saleStart > block.timestamp,
                "Sale start time should be in the future"
            );
            require(
                _saleStart < _saleEnd,
                "Sale end time should be after sale start time"
            );
            // prometaV = IPrometaV(_prometaV);
            saleStart = _saleStart;
            saleEnd = _saleEnd;

            ethPriceFeed = AggregatorV3Interface(
                0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
            );
        }
    //

    event Claimed(address account, uint256 amount);

    /* ONLY OWNER */

        function setAdmin(address _adminAddress) external onlyOwner{
            require(_adminAddress != address(0), "!nonZero");
            adminAddress = _adminAddress;
        }

        function updateSaleStart(uint256 _saleStart) external onlyOwner {
            require(saleStart < block.timestamp, "Sale has already started");
            require(
                _saleStart > block.timestamp,
                "Sale start time should be in the future"
            );

            saleStart = _saleStart;
        }

        function updateSaleEnd(uint256 _saleEnd) external onlyOwner {
            require(
                saleStart < _saleEnd,
                "Sale end time should be after sale start time"
            );
            require(
                _saleEnd > block.timestamp,
                "Sale end time should be in the future"
            );

            saleEnd = _saleEnd;
        }

        function destroy() public onlyOwner nonReentrant {
            // permit the destruction of the contract only an hour after the end of the sale,
            // this avoid any evil miner to trigger the function before the real ending time
            require(
                block.timestamp > saleEnd.add(1 hours),
                "Destruction not enabled yet"
            );
            require(
                supply > 0,
                "Remaining supply already burned or all funds sold"
            );
            uint256 remainingSupply = supply;

            // burn all unsold PrometaV
            supply = 0;
            emit Destroyed(remainingSupply);
        }

        function setPrometaV(address _prometaV) public onlyOwner {
            pmvAddress = _prometaV;
            prometaV = IPrometaV(_prometaV);
        }

        /**
        * Destory the remaining presale supply
        */

    /* GETTERS */
        function isSaleActive() public view returns (bool) {
            return block.timestamp >= saleStart && block.timestamp <= saleEnd;
        }

        function salePriceEth() public view returns (uint256) {
            (, int256 ethPriceUsd, , , ) = ethPriceFeed.latestRoundData();
            uint256 pmvpriceInEth = (salePriceUsd.mul(10**18)).div(uint256(ethPriceUsd).mul(10**10));

            return pmvpriceInEth;
        }

        function computeTokensAmount(uint256 funds) public view returns (uint256, uint256) {
            uint256 salePrice = salePriceEth();
            uint256 tokensToBuy = (funds.div(salePrice)).mul(10**18); // 0.5 6.5 = 6
            uint256 newMinted = distributed.add(tokensToBuy);

            uint256 exceedingEther;


            if (newMinted >= supply) {
                uint256 exceedingTokens = newMinted.sub(supply);
                // Change the tokens to buy to the new number
                tokensToBuy = tokensToBuy.sub(exceedingTokens);

                // Recompute the available funds
                // Convert the exceedingTokens to ether and refund that ether
                uint256 etherUsed = funds.sub(tokensToBuy.mul(salePrice).div(1e18));
                exceedingEther = funds.sub(etherUsed);
            }
            
            return (tokensToBuy, exceedingEther);
        }

    /* EXTERNAL OR PUBLIC */

        receive() external payable {
            // revert("Direct funds receiving not enabled, call 'buy' directly");
        }

        function buy() public payable nonReentrant {
            require(isSaleActive(), "Sale is not active");

            require(supply > 0, "PrivateSale ended, everything was sold");

            // compute the amount of token to buy based on the current rate
            (uint256 tokensToBuy, uint256 exceedingEther) = computeTokensAmount(
                msg.value
            );
            _toClaim[msg.sender] = _toClaim[msg.sender].add(tokensToBuy);


            balance += msg.value;   // add the funds to the balance

            // refund eventually exceeding eth
            if (exceedingEther > 0) {
                uint256 _toRefund = toRefund[msg.sender] + exceedingEther;
                toRefund[msg.sender] = _toRefund;
            }



            distributed = distributed.add(tokensToBuy);

            supply = supply.sub(tokensToBuy);
            // Mint new tokens for each submission
            // prometaV.mint(msg.sender,tokensToBuy);

            // eth deposit of user is stored in _ethDeposit
            _ethDeposit[msg.sender] = _ethDeposit[msg.sender].add(msg.value);

            emit Buy(msg.sender, tokensToBuy);
        }    

        function refund() public nonReentrant {
            require(toRefund[msg.sender] > 0, "Nothing to refund");

            uint256 _refund = toRefund[msg.sender];
            toRefund[msg.sender] = 0;

            // avoid impossibility to refund funds in case transaction are executed from a contract
            // (like gnosis safe multisig), this is a workaround for the 2300 fixed gas problem
            (bool refundSuccess, ) = msg.sender.call{value: _refund}("");
            require(refundSuccess, "Unable to refund exceeding ether");
        }


        // withdraw eth deposit
        function refundETH() external nonReentrant {
            
            require(block.timestamp < saleEnd, "Sale ended");
            require(_ethDeposit[msg.sender] > 0, "No ETH deposit to withdraw");

            payable(msg.sender).transfer(_ethDeposit[msg.sender]);
            
            balance = balance.sub(_ethDeposit[msg.sender]);
            
            _ethDeposit[msg.sender] = 0;
            
            emit withdrawnETHDeposit(msg.sender, _ethDeposit[msg.sender]);
        
        }


        // users can claim pmv tokens
        function claim() external {
            require(block.timestamp > saleEnd, "Sale ended");
            require(_ethDeposit[msg.sender] > 0, "No ETH deposit to claim");

            // prometaV.transfer(msg.sender, _toClaim[msg.sender]);
            prometaV.transfer(msg.sender, _toClaim[msg.sender]);
        //    payable(address(this)).transfer(_toClaim[msg.sender]);
            //   payable(msg.sender).transfer(_toClaim[msg.sender]);
            
            // emit Claimed(msg.sender, _claim);
        }

    //
        // transfer eth to admin
        function transferEthToAdmin() public onlyOwner {
            require(block.timestamp > saleEnd, "Sale not ended");
            require(adminAddress != address(0), "Admin not set");
            
            payable(adminAddress).transfer(balance);
            balance = 0;
        }
 
}