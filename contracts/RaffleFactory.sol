// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Raffle.sol";

contract ContractFactory is Ownable, ReentrancyGuard  {
    address[] public deployedContracts;

    constructor()  Ownable(msg.sender) {}

    function createContract(address tokenAddress, uint256 _ticketPrice, uint256 _startTime, uint256 _endTime) public onlyOwner {
        // Create a new instance of the Raffle contract
        Raffle newContract = new Raffle(tokenAddress, _ticketPrice, _startTime, _endTime, msg.sender);

        // Save the address of the deployed contract
        deployedContracts.push(address(newContract));
    }

    function getDeployedContracts() public view returns (address[] memory) {
        return deployedContracts;
    }
}
