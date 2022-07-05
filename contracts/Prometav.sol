// SPDX-License-Identifier: None
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDEXRouter {
    // function getExchange(address token);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Prometav is IERC20, Ownable {

    using SafeMath for uint256;

        // blacklist of addresses for in-game rewards
        // to keep track of last minting timestamp
        mapping(address => uint256) public _timestamps; 
        mapping(address => bool) public _admins;
        // blacklist of addresses for in-game rewards
        mapping(address => bool) public _blacklisted;

        address adminAddress;

        address public privateSaleAddress;

        IDEXRouter public router;
        //  uint8 constant decimals() = 18;
         uint256 public constant MAX = type(uint256).max;
         uint256 public maxSupply = 3_00_000_000 * (10**decimals());
         uint256 public initialLiquidity = (maxSupply * (10**decimals())).mul(15).div(100);  
         uint256 public teamSupply = (maxSupply * (10**decimals())).mul(15).div(100); 
         uint256 public gameRewards = (maxSupply * (10**decimals())).mul(15).div(100);     
         uint256 public partnersSupply = (maxSupply * (10**decimals())).mul(10).div(100);  
         uint256 public companyReserves = (maxSupply * (10**decimals())).mul(10).div(100);  
         uint256 public marketingSupply = (maxSupply * (10**decimals())).mul(15).div(100);  
         uint256 public developmentSupply = (maxSupply * (10**decimals())).mul(5).div(100);
         uint256 public privateSaleSupply = (maxSupply * (10**decimals())).mul(15).div(100);  
         address DEAD = 0x000000000000000000000000000000000000dEaD;
         address ZERO = 0x0000000000000000000000000000000000000000;
        constructor() ERC20("Prometav", "PMV") {
            adminAddress = msg.sender;
            // adminAddress = _adminAddress;
            // privateSaleAddress = _privateSaleAddress;
            // Exchange Listing & Liquidity
            _mint(address(this), initialLiquidity);
            // Team Supply
            _mint(address(this), teamSupply);
            // Partners & Advisors Supply
            _mint(address(this), partnersSupply);
            // In Game Rewards
            _mint(adminAddress, gameRewards);
            // Company Reserves Supply
            _mint(address(this), companyReserves);
            // Marketing Supply
            _mint(address(this), marketingSupply);
            // Development Supply
            _mint(address(this), developmentSupply);
            // Private Sale Supply
            _mint(address(this), privateSaleSupply);
            // isMember[msg.sender] = true;
        }

        function setBlacklistedUser(address account) external onlyOwner {
            _blacklisted[account] = true;
        }
        function removeBlacklistedUser(address account) external onlyOwner {
            require(_blacklisted[account] == true, "No Blacklisted Found");
            _blacklisted[account] = false;
        }
        function setPrivateSale(address _privateSaleAddress) external onlyOwner {
            privateSaleAddress = _privateSaleAddress;
            // approve max
            _approve(address(this), privateSaleAddress, MAX);
        }

        // to add initial liquidity to the contract
        function addInitialLiquidity() public payable onlyOwner {
        // add the liquidity
        router.addLiquidityETH{value: msg.value}(
            address(this),
            initialLiquidity,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            adminAddress,
            block.timestamp
        );
    }

        function approveMax(address spender) public returns (bool success) {
            return approve(spender, MAX);
        }


}
