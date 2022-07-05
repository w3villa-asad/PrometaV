// SPDX-License-Identifier: None
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDEXRouter {
    // function getExchange(address token);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IPMVPrivateSale {}

contract ProMetaV is ERC20, Ownable {
    using SafeMath for uint256;

    // blacklist of addresses for in-game rewards
    // to keep track of last minting timestamp
    mapping(address => uint256) public _timestamps;
    mapping(address => bool) public _admins;
    // blacklist of addresses for in-game rewards
    mapping(address => bool) public _blacklisted;

    address adminAddress;

    address teamAddress;

    address public privateSaleAddress;

    IDEXRouter public router;
    //  uint8 constant decimals() = 18;
    uint256 public constant MAX = type(uint256).max;
    uint256 public maxSupply = 3_00_000_000 * (10**decimals());
    uint256 public initialLiquidity =
        (maxSupply).mul(15).div(100);
    uint256 public teamSupply = (maxSupply).mul(15).div(100);
    uint256 public gameRewards =
        (maxSupply).mul(15).div(100);
    uint256 public partnersSupply =
        (maxSupply).mul(10).div(100);
    uint256 public companyReserves =
        (maxSupply).mul(10).div(100);
    uint256 public marketingSupply =
        (maxSupply).mul(15).div(100);
    uint256 public developmentSupply =
        (maxSupply).mul(5).div(100);
    uint256 public privateSaleSupply =
        (maxSupply).mul(15).div(100);
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    constructor(address _privateSaleAddress) ERC20("Prometav", "PMV") {
        // adminAddress = msg.sender;
        // adminAddress = _adminAddress;
        privateSaleAddress = _privateSaleAddress;
        // Exchange Listing & Liquidity
        _mint(address(this), initialLiquidity);
        // Team Supply
        _mint(teamAddress, teamSupply);
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
        _mint(_privateSaleAddress, privateSaleSupply);
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

    function setAdmin(address _adminAddress) public onlyOwner {
        require(_adminAddress != address(0), "Admin Address Should Be A Valid Address");
        adminAddress = _adminAddress;
    }

    function setTeam(address _teamAddress) public onlyOwner {
         require(_teamAddress != address(0), "Admin Address Should Be A Valid Address");
        teamAddress = _teamAddress;     
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

    // function approveContract()
}
