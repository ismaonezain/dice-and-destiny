// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DiceAndDestiny {
    enum GameMode { Free, Paid }
    GameMode public currentMode;

    uint256 public constant MIN_BET = 0.00001 ether;
    uint256 public constant MAX_BET = 0.01 ether;

    address public owner;

    mapping(address => uint256) public balances;

    event BetPlaced(address indexed player, uint256 amount);
    event GameResult(address indexed player, uint256 result);
    event Withdraw(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        currentMode = GameMode.Free;  // Default to Free Game mode
    }

    function setGameMode(GameMode mode) public onlyOwner {
        currentMode = mode;
    }

    function rollDice(uint256 betAmount) public payable {
        require(betAmount >= MIN_BET && betAmount <= MAX_BET, "Bet amount out of range.");
        require(msg.value == betAmount, "Incorrect Ether sent.");

        balances[msg.sender] += betAmount;
        emit BetPlaced(msg.sender, betAmount);

        uint256 diceResult = (block.timestamp % 6) + 1;  // Simple dice roll logic based on current timestamp

        emit GameResult(msg.sender, diceResult);

        // Additional payout logic can be implemented based on the dice result and game mode
        if (currentMode == GameMode.Paid) {
            // Example payout logic for Paid mode
            if (diceResult == 6) {
                payable(msg.sender).transfer(betAmount * 2); // Double the bet
            }
        }
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance.");
        payable(owner).transfer(amount);
        emit Withdraw(owner, amount);
    }
}
