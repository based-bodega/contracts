// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Raffle is Ownable {
    IERC20 public token;  // ERC-20 token used for buying tickets
    uint256 public ticketPrice;
    uint256 public startTime;
    uint256 public endTime;
    string public name;
    string public imageUri;
    address[] public participants;
    bool public raffleDrawn = false;
    address public winner;

    event TicketPurchased(address indexed participant, uint256 ticketsBought);
    event RaffleDrawn(address indexed winner, uint256 index);

    modifier onlyDuringRafflePeriod() {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Raffle: Not during the raffle period");
        _;
    }

    modifier onlyAfterRaffle() {
        require(block.timestamp > endTime, "Raffle: Raffle has not ended yet");
        _;
    }

    modifier onlyNotDrawn() {
        require(!raffleDrawn, "Raffle: Winner already drawn");
        _;
    }

    constructor(
        address _tokenAddress,
        uint256 _ticketPrice,
        uint256 _startTime,
        uint256 _endTime,
        address _initialOwner,
        string memory _name,
        string memory _imageUri
    ) Ownable(_initialOwner) {
        token = IERC20(_tokenAddress);
        ticketPrice = _ticketPrice;
        startTime = _startTime;
        endTime = _endTime;
        name = _name;
        imageUri = _imageUri;
    }

    function buyTickets(uint256 _numTickets) external onlyDuringRafflePeriod {
        require(_numTickets > 0, "Raffle: Number of tickets must be greater than 0");

        uint256 totalCost = _numTickets * ticketPrice;

        // Ensure the buyer has enough balance and approves the transfer
        require(token.balanceOf(msg.sender) >= totalCost, "Raffle: Insufficient balance");
        require(token.allowance(msg.sender, address(this)) >= totalCost, "Raffle: Token not approved");

        // Transfer tokens and update participants list
        require(token.transferFrom(msg.sender, address(this), totalCost), "Raffle: Token transfer failed");
        for (uint256 i = 0; i < _numTickets; i++) {
            participants.push(msg.sender);
        }

        emit TicketPurchased(msg.sender, _numTickets);
    }

    function drawRaffle() external onlyOwner onlyAfterRaffle onlyNotDrawn {
        require(participants.length > 0, "Raffle: No participants");

        // Generate a random index to select the winner
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % participants.length;

        winner = participants[randomIndex];
        raffleDrawn = true;

        console.log("Selected winner", winner, randomIndex);
        emit RaffleDrawn(winner, randomIndex);
    }

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }

    function getRaffleStatus() external view returns (bool, bool, bool) {
        bool isOngoing = block.timestamp >= startTime && block.timestamp <= endTime;
        bool hasEnded = block.timestamp > endTime;
        bool isDrawn = raffleDrawn;
        return (isOngoing, hasEnded, isDrawn);
    }

    function getWinner() external view returns (address) {
        require(raffleDrawn, "Raffle: Winner not drawn yet");
        return winner;
    }

    function getRemainingTime() external view returns (uint256) {
        require(block.timestamp < endTime, "Raffle: Raffle has ended");
        return endTime - block.timestamp;
    }

    function getTicketPrice() external view returns (uint256) {
        return ticketPrice;
    }

    function getTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function hasParticipated(address participant) external view returns (bool) {
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i] == participant) {
                return true;
            }
        }
        return false;
    }
}
