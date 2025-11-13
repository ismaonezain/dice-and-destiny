// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GarticPhoneGame {
    struct Player {
        address playerAddress;
        uint256 entryAmount;
    }

    Player[] public players;
    uint256 public totalPool;

    function joinGame() external payable {
        require(msg.value > 0, "Entry amount must be greater than 0");
        players.push(Player(msg.sender, msg.value));
        totalPool += msg.value;
    }

    function getPlayer(uint256 index) external view returns (address, uint256) {
        require(index < players.length, "Player not found");
        Player memory player = players[index];
        return (player.playerAddress, player.entryAmount);
    }

    function getTotalPool() external view returns (uint256) {
        return totalPool;
    }

    function payout(address payable winner) external {
        // Logic for paying out the winner
        winner.transfer(totalPool);
        totalPool = 0; // Reset the pool
        delete players; // Clear players for new game
    }
}