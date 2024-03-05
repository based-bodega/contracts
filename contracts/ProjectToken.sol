// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, ERC20Burnable, Ownable {
    uint256 private constant INITIAL_SUPPLY = 1000000 * (10**18); // 1 million tokens

    constructor() ERC20("MyToken", "MTK") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(this), "Use transferToContract for this token");
        return super.transfer(recipient, amount);
    }

    function transferToContract(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        require(recipient != address(this), "Cannot transfer to the token contract");
        _transfer(_msgSender(), recipient, amount);
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function balanceOf(address account) public view override returns (uint256) {
    return super.balanceOf(account);
}

    function allowance(address owner, address spender) public view override returns (uint256) {
        return super.allowance(owner, spender);
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function decimals() public view virtual override returns (uint8) {
        return super.decimals();
    }
    
    // Additional view functions can be added as needed
}
